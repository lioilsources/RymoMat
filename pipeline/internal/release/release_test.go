package release

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/lioilsources/RymoMat/pipeline/internal/sources"
)

func TestReleaseGate(t *testing.T) {
	dir := t.TempDir()
	pack := filepath.Join(dir, "cs.rpack")
	if err := os.WriteFile(pack, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	o := Options{Lang: "cs", PackPath: pack, OutDir: filepath.Join(dir, "out"), BaseURL: "https://example.org", Version: 1, Schema: 1,
		Sources: []sources.Source{{ID: "kcv", LicenseClass: "by-sa"}, {ID: "fr", LicenseClass: "nc"}}}
	if _, err := Build(o); err == nil {
		t.Fatal("nc source must fail release")
	}
	o.Sources = o.Sources[:1]
	e, err := Build(o)
	if err != nil {
		t.Fatal(err)
	}
	if e.URL != "https://example.org/cs-v1/cs-v1.zip" || e.SHA256 == "" {
		t.Errorf("entry = %+v", e)
	}
	if _, err := os.Stat(filepath.Join(dir, "out", "catalog.json")); err != nil {
		t.Error(err)
	}
}
