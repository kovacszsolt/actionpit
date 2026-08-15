package templatedmail

import (
	"fmt"
	"strings"
)

// SendInput is a one-shot send: templates + data + SMTP + recipient.
type SendInput struct {
	To        string
	SMTP      SMTP
	Templates Templates
	Data      map[string]any
}

// Send compiles templates, renders with Data, and delivers via SMTP.
func Send(in SendInput) error {
	compiled, err := CompileTemplates(in.Templates)
	if err != nil {
		return err
	}
	return compiled.Send(in.To, in.SMTP, in.Data)
}

// Send renders the compiled templates and delivers via SMTP.
func (c *Compiled) Send(to string, smtp SMTP, data map[string]any) error {
	if err := validateSMTP(to, smtp); err != nil {
		return err
	}
	out, err := c.render(data)
	if err != nil {
		return err
	}
	if out.Subject == "" {
		return fmt.Errorf("templatedmail: rendered subject is empty")
	}
	if strings.TrimSpace(out.Text) == "" && strings.TrimSpace(out.HTML) == "" {
		return fmt.Errorf("templatedmail: rendered body is empty")
	}
	return deliver(smtp, to, out.Subject, out.Text, out.HTML)
}

func validateSMTP(to string, smtp SMTP) error {
	if strings.TrimSpace(to) == "" {
		return fmt.Errorf("templatedmail: to is required")
	}
	if strings.TrimSpace(smtp.Endpoint) == "" {
		return fmt.Errorf("templatedmail: smtp endpoint is required")
	}
	if strings.TrimSpace(smtp.FromEmail) == "" {
		return fmt.Errorf("templatedmail: smtp from email is required")
	}
	return nil
}
