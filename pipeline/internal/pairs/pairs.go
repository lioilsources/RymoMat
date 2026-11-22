// Package pairs extracts attested rhyme pairs and citations from annotated poems.
package pairs

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"sort"
	"strings"
	"unicode/utf8"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

// MaxCiteLine is the maximal length of a cited line in characters.
const MaxCiteLine = 80

// MaxCiteCandidates per pair kept for build_pack (which picks at most 2).
const MaxCiteCandidates = 4

type key struct{ a, b string }

// Cite is one candidate citation.
type Cite struct {
	A, B, LineA, LineB, Author, Work string
	Year                             int
}

type agg struct {
	n       int
	authors map[string]bool
}

// Options configure extraction.
type Options struct {
	// CiteText allows citations from the source at all.
	CiteText bool
	// CurrentYear for the public-domain rule death_year + 70 < CurrentYear.
	CurrentYear int
}

// Extractor accumulates pairs over poems.
type Extractor struct {
	opt   Options
	pairs map[key]*agg
	cites map[key][]Cite
	// Golden sample candidates: line-final (form, xsampa).
	Ends [][2]string
}

// NewExtractor returns an empty extractor.
func NewExtractor(opt Options) *Extractor {
	return &Extractor{opt: opt, pairs: map[key]*agg{}, cites: map[key][]Cite{}}
}

// PublicDomain reports whether verses of an author may be cited.
func PublicDomain(deathYear, currentYear int) bool {
	return deathYear > 0 && deathYear+70 < currentYear
}

type end struct {
	form, line string
}

// AddPoem adds all pairs of lines sharing a rhyme index. The index is per poem;
// every pair inside a rhyme group counts once per poem.
func (x *Extractor) AddPoem(p *norm.Poem) {
	groups := map[int][]end{}
	order := []int{}
	for si, st := range p.Words {
		for li, toks := range st {
			wi := norm.LastWord(toks)
			if wi < 0 {
				continue
			}
			form := strings.ToLower(toks[wi].Form)
			if toks[wi].XSampa != "" {
				x.Ends = append(x.Ends, [2]string{form, toks[wi].XSampa})
			}
			if si >= len(p.Rhyme) || li >= len(p.Rhyme[si]) {
				continue
			}
			r := p.Rhyme[si][li]
			if r == 0 {
				continue
			}
			if _, ok := groups[r]; !ok {
				order = append(order, r)
			}
			groups[r] = append(groups[r], end{form, p.Stanzas[si][li]})
		}
	}
	canCite := x.opt.CiteText && PublicDomain(p.DeathYear, x.opt.CurrentYear)
	seen := map[key]bool{}
	for _, r := range order {
		g := groups[r]
		for i := 0; i < len(g); i++ {
			for j := i + 1; j < len(g); j++ {
				a, b := g[i], g[j]
				if a.form == b.form {
					continue
				}
				if a.form > b.form {
					a, b = b, a
				}
				k := key{a.form, b.form}
				if seen[k] {
					continue
				}
				seen[k] = true
				ag := x.pairs[k]
				if ag == nil {
					ag = &agg{authors: map[string]bool{}}
					x.pairs[k] = ag
				}
				ag.n++
				ag.authors[p.Author] = true
				if canCite && utf8.RuneCountInString(a.line) <= MaxCiteLine &&
					utf8.RuneCountInString(b.line) <= MaxCiteLine {
					x.addCite(k, Cite{a.form, b.form, a.line, b.line, p.Author, p.Work, p.Year})
				}
			}
		}
	}
}

// addCite keeps up to MaxCiteCandidates per pair, preferring distinct authors.
func (x *Extractor) addCite(k key, c Cite) {
	list := x.cites[k]
	if len(list) >= MaxCiteCandidates {
		return
	}
	// Beyond two candidates only new authors are worth keeping.
	if len(list) >= 2 {
		for _, o := range list {
			if o.Author == c.Author {
				return
			}
		}
	}
	x.cites[k] = append(list, c)
}

// Stats of the extraction.
func (x *Extractor) Stats() (pairs, occurrences, cites int) {
	for _, a := range x.pairs {
		occurrences += a.n
	}
	for _, l := range x.cites {
		cites += len(l)
	}
	return len(x.pairs), occurrences, cites
}

// WritePairs writes pairs.tsv (a, b, n, authors) sorted by n desc.
func (x *Extractor) WritePairs(path string) error {
	ks := make([]key, 0, len(x.pairs))
	for k := range x.pairs {
		ks = append(ks, k)
	}
	sort.Slice(ks, func(i, j int) bool {
		ni, nj := x.pairs[ks[i]].n, x.pairs[ks[j]].n
		if ni != nj {
			return ni > nj
		}
		if ks[i].a != ks[j].a {
			return ks[i].a < ks[j].a
		}
		return ks[i].b < ks[j].b
	})
	return writeTSV(path, "a\tb\tn\tauthors", func(w *bufio.Writer) {
		for _, k := range ks {
			a := x.pairs[k]
			fmt.Fprintf(w, "%s\t%s\t%d\t%d\n", k.a, k.b, a.n, len(a.authors))
		}
	})
}

// WriteCites writes cites.tsv (a, b, line_a, line_b, author, work, year).
func (x *Extractor) WriteCites(path string) error {
	ks := make([]key, 0, len(x.cites))
	for k := range x.cites {
		ks = append(ks, k)
	}
	sort.Slice(ks, func(i, j int) bool {
		if ks[i].a != ks[j].a {
			return ks[i].a < ks[j].a
		}
		return ks[i].b < ks[j].b
	})
	return writeTSV(path, "a\tb\tline_a\tline_b\tauthor\twork\tyear", func(w *bufio.Writer) {
		for _, k := range ks {
			for _, c := range x.cites[k] {
				y := ""
				if c.Year > 0 {
					y = fmt.Sprint(c.Year)
				}
				fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", c.A, c.B, clean(c.LineA), clean(c.LineB), clean(c.Author), clean(c.Work), y)
			}
		}
	})
}

// WriteGolden writes a deterministic random sample of n line ends (form, xsampa).
func (x *Extractor) WriteGolden(path string, n int, seed int64) error {
	ends := append([][2]string(nil), x.Ends...)
	r := rand.New(rand.NewSource(seed))
	r.Shuffle(len(ends), func(i, j int) { ends[i], ends[j] = ends[j], ends[i] })
	if len(ends) > n {
		ends = ends[:n]
	}
	return writeTSV(path, "form\txsampa", func(w *bufio.Writer) {
		for _, e := range ends {
			fmt.Fprintf(w, "%s\t%s\n", e[0], e[1])
		}
	})
}

func writeTSV(path, header string, body func(*bufio.Writer)) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	w := bufio.NewWriterSize(f, 1<<20)
	fmt.Fprintln(w, header)
	body(w)
	if err := w.Flush(); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

func clean(s string) string { return strings.NewReplacer("\t", " ", "\n", " ").Replace(s) }
