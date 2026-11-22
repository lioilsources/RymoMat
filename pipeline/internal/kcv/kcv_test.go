package kcv

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

// testdata/kcv: three books (Erben 0144, Mácha 0675 and its re-edition 0676), trimmed.
func TestNormalizeSample(t *testing.T) {
	var poems []norm.Poem
	st, err := Normalize("../../testdata/kcv", "by-sa", func(p *norm.Poem) error {
		poems = append(poems, *p)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	// 0676 re-edits Máj with a spelling change (amaranth / amarant), so exact
	// dedup keeps both editions.
	if st.Books != 3 || st.Poems != 9 || st.Duplicates != 0 {
		t.Fatalf("stats = %+v, want 3 books, 9 poems", st)
	}
	var maj *norm.Poem
	for i := range poems {
		if poems[i].Stanzas[0][0] == "Byl pozdní večer – první máj –" {
			maj = &poems[i]
		}
	}
	if maj == nil {
		t.Fatal("Máj not found")
	}
	if maj.Author != "Karel Hynek Mácha" || maj.DeathYear != 1836 || maj.LicenseClass != "by-sa" {
		t.Errorf("metadata = %q %d %q", maj.Author, maj.DeathYear, maj.LicenseClass)
	}
	if len(maj.Rhyme) != len(maj.Stanzas) || len(maj.Words[0]) != len(maj.Stanzas[0]) {
		t.Error("rhyme/words shape differs from stanzas")
	}
	// Máj opens ABBA: máj / háj on lines 1 and 4.
	if r := maj.Rhyme[0]; r[0] == 0 || r[0] != r[3] || r[1] != r[2] {
		t.Errorf("rhyme index of first stanza = %v", r)
	}
	last := maj.Words[0][0][norm.LastWord(maj.Words[0][0])]
	if last.Form != "máj" || last.XSampa == "" || last.Lemma == "" || len(last.Tag) < 12 {
		t.Errorf("last token = %+v", last)
	}
}

func TestDisplayName(t *testing.T) {
	if got := displayName("Mácha, Karel Hynek"); got != "Karel Hynek Mácha" {
		t.Error(got)
	}
}

func TestDedupIdenticalReedition(t *testing.T) {
	dir := t.TempDir()
	b, err := os.ReadFile("../../testdata/kcv/0144.json")
	if err != nil {
		t.Fatal(err)
	}
	for _, n := range []string{"0001.json", "0002.json"} {
		if err := os.WriteFile(filepath.Join(dir, n), b, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	st, err := Normalize(dir, "by-sa", func(*norm.Poem) error { return nil })
	if err != nil {
		t.Fatal(err)
	}
	if st.Poems != 3 || st.Duplicates != 3 {
		t.Fatalf("stats = %+v", st)
	}
}
