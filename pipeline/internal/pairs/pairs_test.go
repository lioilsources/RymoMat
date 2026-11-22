package pairs

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

func tok(f string) []norm.Token { return []norm.Token{{Form: "a"}, {Form: f}, {Form: ","}} }

func poem(author string, died int) *norm.Poem {
	return &norm.Poem{
		Author: author, DeathYear: died, Work: "Dílo",
		Stanzas: [][]string{{"byl máj", "a les", "zelený háj", "pes"}},
		Rhyme:   [][]int{{1, 2, 1, 2}},
		Words:   [][][]norm.Token{{tok("Máj"), tok("les"), tok("háj"), tok("pes")}},
	}
}

func TestExtract(t *testing.T) {
	x := NewExtractor(Options{CiteText: true, CurrentYear: 2026})
	x.AddPoem(poem("A", 1836))
	x.AddPoem(poem("B", 1990)) // not public domain: counted, not cited
	np, occ, nc := x.Stats()
	if np != 2 || occ != 4 || nc != 2 {
		t.Fatalf("pairs=%d occ=%d cites=%d", np, occ, nc)
	}
	dir := t.TempDir()
	if err := x.WritePairs(filepath.Join(dir, "p.tsv")); err != nil {
		t.Fatal(err)
	}
	b, _ := os.ReadFile(filepath.Join(dir, "p.tsv"))
	if !strings.Contains(string(b), "háj\tmáj\t2\t2\n") {
		t.Errorf("pairs.tsv:\n%s", b)
	}
}

func TestPublicDomain(t *testing.T) {
	if !PublicDomain(1955, 2026) || PublicDomain(1956, 2026) || PublicDomain(0, 2026) {
		t.Error("death_year + 70 < year rule broken")
	}
}
