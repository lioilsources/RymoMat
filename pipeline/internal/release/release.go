// Package release zips a rhyme pack with manifest and attribution and updates catalog.json.
package release

import (
	"archive/zip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/lioilsources/RymoMat/pipeline/internal/sources"
)

// Manifest is manifest.json inside the pack zip.
type Manifest struct {
	Schema  int              `json:"schema"`
	Lang    string           `json:"lang"`
	Version int              `json:"version"`
	SHA256  string           `json:"sha256"`
	Size    int64            `json:"size"`
	License string           `json:"license"`
	Sources []sources.Source `json:"sources"`
}

// CatalogEntry is one pack in catalog.json.
type CatalogEntry struct {
	Lang     string `json:"lang"`
	Version  int    `json:"version"`
	Schema   int    `json:"schema"`
	URL      string `json:"url"`
	SHA256   string `json:"sha256"`
	Size     int64  `json:"size"`
	Unpacked int64  `json:"unpacked"`
	License  string `json:"license"`
}

// Catalog is catalog.json of the rymomat-packs repo.
type Catalog struct {
	Packs []CatalogEntry `json:"packs"`
}

// Options for Build.
type Options struct {
	Lang, PackPath, OutDir, BaseURL string
	Version, Schema                 int
	Sources                         []sources.Source
	Research                        bool
}

// Build writes <lang>-v<N>.zip into OutDir and merges the entry into OutDir/catalog.json.
func Build(o Options) (CatalogEntry, error) {
	if err := sources.Gate(o.Sources, o.Research); err != nil {
		return CatalogEntry{}, err
	}
	packSum, packSize, err := hashFile(o.PackPath)
	if err != nil {
		return CatalogEntry{}, err
	}
	m := Manifest{Schema: o.Schema, Lang: o.Lang, Version: o.Version, SHA256: packSum, Size: packSize, License: "CC BY-SA 4.0", Sources: o.Sources}
	if err := os.MkdirAll(o.OutDir, 0o755); err != nil {
		return CatalogEntry{}, err
	}
	name := fmt.Sprintf("%s-v%d", o.Lang, o.Version)
	zipPath := filepath.Join(o.OutDir, name+".zip")
	if err := writeZip(zipPath, o.Lang, o.PackPath, m); err != nil {
		return CatalogEntry{}, err
	}
	zipSum, zipSize, err := hashFile(zipPath)
	if err != nil {
		return CatalogEntry{}, err
	}
	e := CatalogEntry{Lang: o.Lang, Version: o.Version, Schema: o.Schema, URL: strings.TrimRight(o.BaseURL, "/") + "/" + name + "/" + name + ".zip",
		SHA256: zipSum, Size: zipSize, Unpacked: packSize, License: m.License}
	return e, mergeCatalog(filepath.Join(o.OutDir, "catalog.json"), e)
}

// Attribution renders ATTRIBUTION.md.
func Attribution(lang string, srcs []sources.Source) string {
	var b strings.Builder
	fmt.Fprintf(&b, "# Rhyme pack `%s` — atribuce\n\n", lang)
	b.WriteString("Pack je odvozené dílo a šíří se pod licencí CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).\n\n## Zdroje\n\n")
	for _, s := range srcs {
		fmt.Fprintf(&b, "- **%s** (%s), %s — %s\n", s.ID, s.URL, s.License, strings.TrimSpace(s.Attribution))
	}
	return b.String()
}

func writeZip(path, lang, packPath string, m Manifest) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	zw := zip.NewWriter(f)
	add := func(name string, r io.Reader) error {
		w, err := zw.Create(name)
		if err != nil {
			return err
		}
		_, err = io.Copy(w, r)
		return err
	}
	pf, err := os.Open(packPath)
	if err != nil {
		f.Close()
		return err
	}
	defer pf.Close()
	mj, _ := json.MarshalIndent(m, "", "  ")
	for _, step := range []func() error{
		func() error { return add(lang+".rpack", pf) },
		func() error { return add("manifest.json", strings.NewReader(string(mj)+"\n")) },
		func() error { return add("ATTRIBUTION.md", strings.NewReader(Attribution(lang, m.Sources))) },
		zw.Close,
	} {
		if err := step(); err != nil {
			f.Close()
			return fmt.Errorf("zip %s: %w", path, err)
		}
	}
	return f.Close()
}

func mergeCatalog(path string, e CatalogEntry) error {
	var c Catalog
	if b, err := os.ReadFile(path); err == nil {
		if err := json.Unmarshal(b, &c); err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}
	}
	out := c.Packs[:0]
	for _, p := range c.Packs {
		if p.Lang != e.Lang {
			out = append(out, p)
		}
	}
	c.Packs = append(out, e)
	sort.Slice(c.Packs, func(i, j int) bool { return c.Packs[i].Lang < c.Packs[j].Lang })
	b, _ := json.MarshalIndent(c, "", "  ")
	return os.WriteFile(path, append(b, '\n'), 0o644)
}

func hashFile(path string) (string, int64, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", 0, err
	}
	defer f.Close()
	h := sha256.New()
	n, err := io.Copy(h, f)
	if err != nil {
		return "", 0, err
	}
	return hex.EncodeToString(h.Sum(nil)), n, nil
}
