// Package lexicon builds lexicon.tsv (form, freq, lemma, gram). It never computes phonemes (plan R2).
package lexicon

import (
	"bufio"
	"fmt"
	"io"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

// Entry is one lexicon row.
type Entry struct {
	Form  string
	Freq  int
	Lemma string
	Tag   string
}

type analysis struct{ lemma, tag string }

// Counter accumulates corpus counts.
type Counter struct {
	counts map[string]int
	ana    map[string]map[analysis]int
	total  int
}

// NewCounter returns an empty counter.
func NewCounter() *Counter {
	return &Counter{counts: map[string]int{}, ana: map[string]map[analysis]int{}}
}

// AddPoem counts all word tokens of a poem.
func (c *Counter) AddPoem(p *norm.Poem) {
	for _, st := range p.Words {
		for _, l := range st {
			for _, t := range l {
				f := strings.ToLower(t.Form)
				if !IsCzechWord(f) {
					continue
				}
				c.counts[f]++
				c.total++
				m := c.ana[f]
				if m == nil {
					m = map[analysis]int{}
					c.ana[f] = m
				}
				m[analysis{t.Lemma, t.Tag}]++
			}
		}
	}
}

// IsCzechWord accepts lowercase words made of Czech (and q, w, x) letters.
func IsCzechWord(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if (r < 'a' || r > 'z') && !strings.ContainsRune("áčďéěíňóřšťúůýž", r) {
			return false
		}
	}
	return true
}

// ReadFrequencyWords parses "word count" lines (hermitdave/FrequencyWords).
func ReadFrequencyWords(r io.Reader) (map[string]int, int, error) {
	out := map[string]int{}
	total := 0
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		parts := strings.Fields(sc.Text())
		if len(parts) != 2 {
			continue
		}
		n, err := strconv.Atoi(parts[1])
		if err != nil {
			continue
		}
		total += n
		w := strings.ToLower(parts[0])
		if IsCzechWord(w) {
			out[w] += n
		}
	}
	return out, total, sc.Err()
}

// Build merges corpus counts (min count minCorpus) with a frequency list.
// freq = max of both counts normalized to occurrences per billion tokens (at least 1).
func Build(c *Counter, freqList map[string]int, freqTotal, minCorpus int) []Entry {
	perBillion := func(n, total int) int {
		if total == 0 {
			return 0
		}
		return int(math.Max(1, math.Round(float64(n)*1e9/float64(total))))
	}
	byForm := map[string]*Entry{}
	for f, n := range c.counts {
		if n < minCorpus {
			continue
		}
		e := &Entry{Form: f, Freq: perBillion(n, c.total)}
		best := 0
		for a, k := range c.ana[f] {
			if k > best || (k == best && a.lemma < e.Lemma) {
				best, e.Lemma, e.Tag = k, a.lemma, a.tag
			}
		}
		byForm[f] = e
	}
	for f, n := range freqList {
		v := perBillion(n, freqTotal)
		if e := byForm[f]; e != nil {
			if v > e.Freq {
				e.Freq = v
			}
			continue
		}
		byForm[f] = &Entry{Form: f, Freq: v}
	}
	out := make([]Entry, 0, len(byForm))
	for _, e := range byForm {
		out = append(out, *e)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Form < out[j].Form })
	return out
}

// WriteTSV writes lexicon.tsv with a header.
func WriteTSV(path string, entries []Entry) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	w := bufio.NewWriter(f)
	fmt.Fprintln(w, "form\tfreq\tlemma\tgram")
	for _, e := range entries {
		fmt.Fprintf(w, "%s\t%d\t%s\t%s\n", e.Form, e.Freq, clean(e.Lemma), clean(e.Tag))
	}
	if err := w.Flush(); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

func clean(s string) string { return strings.NewReplacer("\t", " ", "\n", " ").Replace(s) }
