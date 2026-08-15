package templatedmail

import (
	"fmt"
	"strings"

	"github.com/aymerick/raymond"
)

// Templates holds Handlebars source strings provided by the caller.
type Templates struct {
	Subject string // required
	Text    string // plain body; required if HTML is empty
	HTML    string // optional HTML body
}

// Compiled holds pre-parsed Handlebars templates for repeated sends.
type Compiled struct {
	subject *raymond.Template
	text    *raymond.Template
	html    *raymond.Template
}

// CompileTemplates parses Handlebars templates once for reuse.
func CompileTemplates(t Templates) (*Compiled, error) {
	subjectSrc := strings.TrimSpace(t.Subject)
	if subjectSrc == "" {
		return nil, fmt.Errorf("templatedmail: subject template is required")
	}
	textSrc := strings.TrimSpace(t.Text)
	htmlSrc := strings.TrimSpace(t.HTML)
	if textSrc == "" && htmlSrc == "" {
		return nil, fmt.Errorf("templatedmail: text or html body template is required")
	}

	subject, err := raymond.Parse(subjectSrc)
	if err != nil {
		return nil, fmt.Errorf("templatedmail: parse subject: %w", err)
	}

	c := &Compiled{subject: subject}
	if textSrc != "" {
		text, err := raymond.Parse(textSrc)
		if err != nil {
			return nil, fmt.Errorf("templatedmail: parse text: %w", err)
		}
		c.text = text
	}
	if htmlSrc != "" {
		html, err := raymond.Parse(htmlSrc)
		if err != nil {
			return nil, fmt.Errorf("templatedmail: parse html: %w", err)
		}
		c.html = html
	}
	return c, nil
}

type rendered struct {
	Subject string
	Text    string
	HTML    string
}

func (c *Compiled) render(data map[string]any) (rendered, error) {
	if c == nil || c.subject == nil {
		return rendered{}, fmt.Errorf("templatedmail: compiled templates are nil")
	}
	if data == nil {
		data = map[string]any{}
	}

	subject, err := c.subject.Exec(data)
	if err != nil {
		return rendered{}, fmt.Errorf("templatedmail: render subject: %w", err)
	}

	out := rendered{Subject: strings.TrimSpace(subject)}
	if c.text != nil {
		text, err := c.text.Exec(data)
		if err != nil {
			return rendered{}, fmt.Errorf("templatedmail: render text: %w", err)
		}
		out.Text = text
	}
	if c.html != nil {
		html, err := c.html.Exec(data)
		if err != nil {
			return rendered{}, fmt.Errorf("templatedmail: render html: %w", err)
		}
		out.HTML = html
	}
	return out, nil
}
