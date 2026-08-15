package templatedmail

import (
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"net"
	"net/smtp"
	"strings"
	"time"
)

// SMTP holds connection and From identity settings.
type SMTP struct {
	Endpoint  string
	Port      int
	Username  string
	Password  string
	FromEmail string
	FromName  string
	UseTLS    bool
}

// SendError wraps SMTP delivery failures.
type SendError struct {
	Message string
}

func (e SendError) Error() string {
	return e.Message
}

// loginAuth implements SMTP AUTH LOGIN (required by Azure Communication Services /
// Exchange Online). Go's smtp.PlainAuth uses AUTH PLAIN, which ACS rejects with
// 504 5.7.4 Unrecognized authentication type.
type loginAuth struct {
	username, password string
}

func newLoginAuth(username, password string) smtp.Auth {
	return &loginAuth{username: username, password: password}
}

func (a *loginAuth) Start(_ *smtp.ServerInfo) (string, []byte, error) {
	return "LOGIN", nil, nil
}

func (a *loginAuth) Next(fromServer []byte, more bool) ([]byte, error) {
	if !more {
		return nil, nil
	}
	challenge := strings.TrimSpace(string(fromServer))
	if decoded, err := base64.StdEncoding.DecodeString(challenge); err == nil && len(decoded) > 0 {
		challenge = string(decoded)
	}
	switch {
	case strings.Contains(strings.ToLower(challenge), "user"):
		return []byte(a.username), nil
	case strings.Contains(strings.ToLower(challenge), "pass"):
		return []byte(a.password), nil
	default:
		return nil, fmt.Errorf("unexpected server challenge: %q", fromServer)
	}
}

func deliver(settings SMTP, toEmail, subject, textBody, htmlBody string) error {
	host := strings.TrimSpace(settings.Endpoint)
	if host == "" {
		return SendError{Message: "smtp_endpoint is empty"}
	}
	toEmail = strings.TrimSpace(toEmail)
	if toEmail == "" {
		return SendError{Message: "to email is empty"}
	}
	port := settings.Port
	if port <= 0 {
		port = 587
	}
	addr := fmt.Sprintf("%s:%d", host, port)
	from := strings.TrimSpace(settings.FromEmail)
	if from == "" {
		return SendError{Message: "from_email is empty"}
	}
	fromHeader := from
	if name := strings.TrimSpace(settings.FromName); name != "" {
		fromHeader = fmt.Sprintf("%s <%s>", name, from)
	}

	msg, err := buildMIMEMessage(fromHeader, toEmail, subject, textBody, htmlBody)
	if err != nil {
		return SendError{Message: err.Error()}
	}

	auth := newLoginAuth(settings.Username, settings.Password)
	deadline := time.Now().Add(30 * time.Second)

	if port == 465 {
		return sendImplicitTLS(addr, host, auth, from, toEmail, msg, deadline)
	}
	if settings.UseTLS || port == 587 {
		return sendStartTLS(addr, host, auth, from, toEmail, msg, deadline)
	}
	return sendPlain(addr, host, auth, from, toEmail, msg, deadline)
}

func buildMIMEMessage(fromHeader, toEmail, subject, textBody, htmlBody string) ([]byte, error) {
	var msg strings.Builder
	msg.WriteString("From: " + fromHeader + "\r\n")
	msg.WriteString("To: " + toEmail + "\r\n")
	msg.WriteString("Subject: " + subject + "\r\n")
	msg.WriteString("MIME-Version: 1.0\r\n")

	hasText := strings.TrimSpace(textBody) != ""
	hasHTML := strings.TrimSpace(htmlBody) != ""

	switch {
	case hasText && hasHTML:
		boundary, err := randomBoundary()
		if err != nil {
			return nil, err
		}
		msg.WriteString("Content-Type: multipart/alternative; boundary=\"" + boundary + "\"\r\n")
		msg.WriteString("\r\n")
		msg.WriteString("--" + boundary + "\r\n")
		msg.WriteString("Content-Type: text/plain; charset=UTF-8\r\n")
		msg.WriteString("Content-Transfer-Encoding: 8bit\r\n\r\n")
		msg.WriteString(textBody)
		msg.WriteString("\r\n")
		msg.WriteString("--" + boundary + "\r\n")
		msg.WriteString("Content-Type: text/html; charset=UTF-8\r\n")
		msg.WriteString("Content-Transfer-Encoding: 8bit\r\n\r\n")
		msg.WriteString(htmlBody)
		msg.WriteString("\r\n")
		msg.WriteString("--" + boundary + "--\r\n")
	case hasHTML:
		msg.WriteString("Content-Type: text/html; charset=UTF-8\r\n\r\n")
		msg.WriteString(htmlBody)
	default:
		msg.WriteString("Content-Type: text/plain; charset=UTF-8\r\n\r\n")
		msg.WriteString(textBody)
	}
	return []byte(msg.String()), nil
}

func randomBoundary() (string, error) {
	var b [12]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", fmt.Errorf("boundary: %w", err)
	}
	return "templatedmail_" + hex.EncodeToString(b[:]), nil
}

func sendPlain(addr, host string, auth smtp.Auth, from, to string, msg []byte, deadline time.Time) error {
	conn, err := net.DialTimeout("tcp", addr, 15*time.Second)
	if err != nil {
		return SendError{Message: fmt.Sprintf("dial: %v", err)}
	}
	defer conn.Close()
	_ = conn.SetDeadline(deadline)

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return SendError{Message: fmt.Sprintf("smtp client: %v", err)}
	}
	defer func() { _ = client.Close() }()

	return finishSMTP(client, auth, from, to, msg)
}

func sendStartTLS(addr, host string, auth smtp.Auth, from, to string, msg []byte, deadline time.Time) error {
	conn, err := net.DialTimeout("tcp", addr, 15*time.Second)
	if err != nil {
		return SendError{Message: fmt.Sprintf("dial: %v", err)}
	}
	defer conn.Close()
	_ = conn.SetDeadline(deadline)

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return SendError{Message: fmt.Sprintf("smtp client: %v", err)}
	}
	defer func() { _ = client.Close() }()

	if ok, _ := client.Extension("STARTTLS"); !ok {
		return SendError{Message: "server does not support STARTTLS"}
	}
	tlsConfig := &tls.Config{ServerName: host, MinVersion: tls.VersionTLS12}
	if err := client.StartTLS(tlsConfig); err != nil {
		return SendError{Message: fmt.Sprintf("starttls: %v", err)}
	}
	return finishSMTP(client, auth, from, to, msg)
}

func sendImplicitTLS(addr, host string, auth smtp.Auth, from, to string, msg []byte, deadline time.Time) error {
	tlsConfig := &tls.Config{ServerName: host, MinVersion: tls.VersionTLS12}
	dialer := &net.Dialer{Timeout: 15 * time.Second}
	conn, err := tls.DialWithDialer(dialer, "tcp", addr, tlsConfig)
	if err != nil {
		return SendError{Message: fmt.Sprintf("tls dial: %v", err)}
	}
	defer conn.Close()
	_ = conn.SetDeadline(deadline)

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return SendError{Message: fmt.Sprintf("smtp client: %v", err)}
	}
	defer func() { _ = client.Close() }()

	return finishSMTP(client, auth, from, to, msg)
}

func finishSMTP(client *smtp.Client, auth smtp.Auth, from, to string, msg []byte) error {
	if err := client.Auth(auth); err != nil {
		return SendError{Message: fmt.Sprintf("auth: %v", err)}
	}
	if err := client.Mail(from); err != nil {
		return SendError{Message: fmt.Sprintf("mail from: %v", err)}
	}
	if err := client.Rcpt(to); err != nil {
		return SendError{Message: fmt.Sprintf("rcpt to: %v", err)}
	}
	w, err := client.Data()
	if err != nil {
		return SendError{Message: fmt.Sprintf("data: %v", err)}
	}
	if _, err := w.Write(msg); err != nil {
		_ = w.Close()
		return SendError{Message: fmt.Sprintf("write: %v", err)}
	}
	if err := w.Close(); err != nil {
		return SendError{Message: fmt.Sprintf("data close: %v", err)}
	}
	if err := client.Quit(); err != nil {
		return SendError{Message: fmt.Sprintf("quit: %v", err)}
	}
	return nil
}
