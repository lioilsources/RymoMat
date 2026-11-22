// Package kcv normalizes the Corpus of Czech Verse (github.com/versotym/corpusCzechVerse).
//
// Each ccv/*.json file is a JSON array of poems. The rhyme index is per poem:
// lines sharing a value rhyme, numbering continues across stanzas, null = no rhyme.
package kcv

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

type author struct {
	Identity string `json:"identity"`
	Name     string `json:"name"`
	Died     *int   `json:"died"`
}

type word struct {
	Token  string `json:"token"`
	Lemma  string `json:"lemma"`
	Morph  string `json:"morph"`
	XSampa string `json:"xsampa"`
}

type line struct {
	Text  string `json:"text"`
	Rhyme *int   `json:"rhyme"`
	Words []word `json:"words"`
}

type poem struct {
	BookID  string `json:"book_id"`
	PoemID  string `json:"poem_id"`
	PAuthor author `json:"p_author"`
	BAuthor author `json:"b_author"`
	Biblio  struct {
		PTitle string          `json:"p_title"`
		BTitle string          `json:"b_title"`
		Year   json.RawMessage `json:"year"`
	} `json:"biblio"`
	Body [][]line `json:"body"`
}

// Stats summarizes a normalization run.
type Stats struct {
	Books, Poems, Duplicates, Lines int
}

// Normalize streams deduplicated poems of all books under dir (raw repo root
// or its ccv/ folder) to fn, in book order.
func Normalize(dir, licenseClass string, fn func(*norm.Poem) error) (Stats, error) {
	var st Stats
	if fi, err := os.Stat(filepath.Join(dir, "ccv")); err == nil && fi.IsDir() {
		dir = filepath.Join(dir, "ccv")
	}
	files, err := filepath.Glob(filepath.Join(dir, "*.json"))
	if err != nil {
		return st, err
	}
	sort.Strings(files)
	seen := map[[32]byte]bool{}
	for _, f := range files {
		b, err := os.ReadFile(f)
		if err != nil {
			return st, err
		}
		var poems []poem
		if err := json.Unmarshal(b, &poems); err != nil {
			return st, fmt.Errorf("%s: %w", f, err)
		}
		st.Books++
		for i := range poems {
			p := convert(&poems[i], licenseClass)
			k := sha256.Sum256([]byte(p.Key()))
			if seen[k] {
				st.Duplicates++
				continue
			}
			seen[k] = true
			st.Poems++
			for _, s := range p.Stanzas {
				st.Lines += len(s)
			}
			if err := fn(&p); err != nil {
				return st, err
			}
		}
	}
	return st, nil
}

func convert(p *poem, licenseClass string) norm.Poem {
	a := p.PAuthor
	if a.Identity == "" {
		a = p.BAuthor
	}
	n := norm.Poem{
		PoemID:       p.BookID + "/" + p.PoemID,
		Author:       displayName(a.Identity),
		Year:         parseYear(p.Biblio.Year),
		Work:         strings.TrimSpace(p.Biblio.BTitle),
		Lang:         "cs",
		LicenseClass: licenseClass,
	}
	if a.Died != nil {
		n.DeathYear = *a.Died
	}
	for _, st := range p.Body {
		var lines []string
		var rh []int
		var ws [][]norm.Token
		for _, l := range st {
			lines = append(lines, strings.TrimSpace(l.Text))
			r := 0
			if l.Rhyme != nil {
				r = *l.Rhyme
			}
			rh = append(rh, r)
			toks := make([]norm.Token, 0, len(l.Words))
			for _, w := range l.Words {
				toks = append(toks, norm.Token{Form: w.Token, Lemma: w.Lemma, Tag: w.Morph, XSampa: w.XSampa})
			}
			ws = append(ws, toks)
		}
		n.Stanzas = append(n.Stanzas, lines)
		n.Rhyme = append(n.Rhyme, rh)
		n.Words = append(n.Words, ws)
	}
	return n
}

// displayName turns "Mácha, Karel Hynek" into "Karel Hynek Mácha".
func displayName(s string) string {
	s = strings.TrimSpace(s)
	if i := strings.Index(s, ", "); i > 0 {
		return strings.TrimSpace(s[i+2:]) + " " + s[:i]
	}
	return s
}

func parseYear(raw json.RawMessage) int {
	s := strings.Trim(string(raw), `" `)
	if len(s) >= 4 {
		if y, err := strconv.Atoi(s[:4]); err == nil {
			return y
		}
	}
	return 0
}
