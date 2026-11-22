package lexicon

import (
	"strings"
	"testing"

	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
)

func TestBuild(t *testing.T) {
	c := NewCounter()
	p := &norm.Poem{Words: [][][]norm.Token{{{
		{Form: "Máj", Lemma: "máj", Tag: "NNIS1-----A----"},
		{Form: "máj", Lemma: "máj", Tag: "NNIS1-----A----"},
		{Form: "háj", Lemma: "háj", Tag: "NNIS1-----A----"},
		{Form: "–"},
	}}}}
	c.AddPoem(p)
	fl, total, err := ReadFrequencyWords(strings.NewReader("máj 10\nauto 90\nok! 5\n"))
	if err != nil || total != 105 || len(fl) != 2 {
		t.Fatalf("freq list = %v %d %v", fl, total, err)
	}
	got := map[string]Entry{}
	for _, e := range Build(c, fl, total, 2) {
		got[e.Form] = e
	}
	if _, ok := got["háj"]; ok {
		t.Error("háj is below the corpus minimum and not in the frequency list")
	}
	if got["máj"].Lemma != "máj" || got["auto"].Lemma != "" || got["auto"].Freq == 0 {
		t.Errorf("entries = %+v", got)
	}
	// máj: corpus 2/3 = 666666667 per billion beats list 10/105.
	if got["máj"].Freq != 666666667 {
		t.Errorf("freq = %d", got["máj"].Freq)
	}
}
