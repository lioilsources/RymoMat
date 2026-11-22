// Package norm defines the normalized poem format (work/norm/<id>.jsonl).
package norm

import (
	"bufio"
	"encoding/json"
	"os"
	"strings"
	"unicode"
)

// Token is one word of a line.
type Token struct {
	Form   string `json:"f"`
	Lemma  string `json:"l,omitempty"`
	Tag    string `json:"t,omitempty"`
	XSampa string `json:"x,omitempty"`
}

// Poem is one normalized poem.
type Poem struct {
	PoemID       string     `json:"poem_id"`
	Author       string     `json:"author"`
	DeathYear    int        `json:"death_year,omitempty"`
	Year         int        `json:"year,omitempty"`
	Work         string     `json:"work"`
	Lang         string     `json:"lang"`
	LicenseClass string     `json:"license_class"`
	Stanzas      [][]string `json:"stanzas"`
	// KČV only: rhyme index per line (0 = none), same shape as Stanzas.
	Rhyme [][]int `json:"rhyme,omitempty"`
	// KČV only: tokens per line, same shape as Stanzas.
	Words [][][]Token `json:"words,omitempty"`
}

// Key returns a hash key of the normalized text used for re-edition dedup.
func (p *Poem) Key() string {
	var b strings.Builder
	for _, st := range p.Stanzas {
		for _, l := range st {
			for _, r := range strings.ToLower(l) {
				if unicode.IsLetter(r) {
					b.WriteRune(r)
				}
			}
			b.WriteByte('\n')
		}
	}
	return b.String()
}

// Writer writes poems as JSON lines.
type Writer struct {
	f   *os.File
	w   *bufio.Writer
	enc *json.Encoder
}

// Create opens a JSON lines file for writing.
func Create(path string) (*Writer, error) {
	f, err := os.Create(path)
	if err != nil {
		return nil, err
	}
	w := bufio.NewWriterSize(f, 1<<20)
	enc := json.NewEncoder(w)
	enc.SetEscapeHTML(false)
	return &Writer{f, w, enc}, nil
}

// Write appends one poem.
func (w *Writer) Write(p *Poem) error { return w.enc.Encode(p) }

// Close flushes and closes the file.
func (w *Writer) Close() error {
	if err := w.w.Flush(); err != nil {
		w.f.Close()
		return err
	}
	return w.f.Close()
}

// Each streams poems from a JSON lines file.
func Each(path string, fn func(*Poem) error) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 64<<20)
	for sc.Scan() {
		var p Poem
		if err := json.Unmarshal(sc.Bytes(), &p); err != nil {
			return err
		}
		if err := fn(&p); err != nil {
			return err
		}
	}
	return sc.Err()
}

// IsWord reports whether s contains only letters.
func IsWord(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if !unicode.IsLetter(r) {
			return false
		}
	}
	return true
}

// LastWord returns the index of the last token of a line that is a word, or -1.
func LastWord(toks []Token) int {
	for i := len(toks) - 1; i >= 0; i-- {
		if IsWord(strings.ToLower(toks[i].Form)) {
			return i
		}
	}
	return -1
}
