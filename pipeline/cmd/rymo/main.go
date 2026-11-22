// Command rymo is the RymoMat data pipeline: fetch | normalize | lexicon | pairs | pack | eval | release.
package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/lioilsources/RymoMat/pipeline/internal/kcv"
	"github.com/lioilsources/RymoMat/pipeline/internal/lexicon"
	"github.com/lioilsources/RymoMat/pipeline/internal/norm"
	"github.com/lioilsources/RymoMat/pipeline/internal/pairs"
	"github.com/lioilsources/RymoMat/pipeline/internal/release"
	"github.com/lioilsources/RymoMat/pipeline/internal/sources"
)

const userAgent = "RymoMat-pipeline/0.1 (+https://github.com/lioilsources/RymoMat)"

type env struct {
	root, work string
	reg        sources.Registry
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	root, err := findRoot()
	if err != nil {
		fail(err)
	}
	reg, err := sources.Load(filepath.Join(root, "pipeline", "sources.yaml"))
	if err != nil {
		fail(err)
	}
	e := &env{root: root, work: filepath.Join(root, "work"), reg: reg}
	cmd, args := os.Args[1], os.Args[2:]
	switch cmd {
	case "fetch":
		err = e.fetch(args)
	case "normalize":
		err = e.normalize(args)
	case "lexicon":
		err = e.lexicon(args)
	case "pairs":
		err = e.pairs(args)
	case "pack":
		err = e.pack(args)
	case "eval":
		err = e.eval(args)
	case "release":
		err = e.release(args)
	default:
		usage()
	}
	if err != nil {
		fail(err)
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: rymo fetch <id> | normalize <id> | lexicon <lang> | pairs <lang> | pack <lang> | eval <lang> | release <lang> [--research]")
	os.Exit(2)
}

func fail(err error) {
	slog.Error("rymo", "err", err)
	os.Exit(1)
}

// findRoot walks up from the working directory to the repo root (pipeline/sources.yaml).
func findRoot() (string, error) {
	d, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(d, "pipeline", "sources.yaml")); err == nil {
			return d, nil
		}
		p := filepath.Dir(d)
		if p == d {
			return "", errors.New("repo root with pipeline/sources.yaml not found")
		}
		d = p
	}
}

func one(args []string, what string) (string, error) {
	if len(args) < 1 {
		return "", fmt.Errorf("missing %s", what)
	}
	return args[0], nil
}

func (e *env) fetch(args []string) error {
	id, err := one(args, "source id")
	if err != nil {
		return err
	}
	s, err := e.reg.Get(id)
	if err != nil {
		return err
	}
	dst := filepath.Join(e.work, "raw", id)
	switch s.Kind {
	case "git":
		if _, err := os.Stat(filepath.Join(dst, ".git")); err == nil {
			slog.Info("fetch: already present, pulling", "id", id)
			return run("", "git", "-C", dst, "pull", "--ff-only", "-q")
		}
		if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
			return err
		}
		return run("", "git", "clone", "--depth", "1", "-q", s.URL, dst)
	case "file":
		file := filepath.Join(dst, path.Base(s.URL))
		if _, err := os.Stat(file); err == nil {
			slog.Info("fetch: cached", "file", file)
			return nil
		}
		if err := os.MkdirAll(dst, 0o755); err != nil {
			return err
		}
		return download(s.URL, file)
	default:
		return fmt.Errorf("fetch kind %q is not implemented yet (M3)", s.Kind)
	}
}

func download(url, file string) error {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", userAgent)
	c := &http.Client{Timeout: 10 * time.Minute}
	resp, err := c.Do(req)
	if err != nil {
		return fmt.Errorf("download %s: %w", url, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download %s: %s", url, resp.Status)
	}
	tmp := file + ".part"
	f, err := os.Create(tmp)
	if err != nil {
		return err
	}
	if _, err := io.Copy(f, resp.Body); err != nil {
		f.Close()
		return fmt.Errorf("download %s: %w", url, err)
	}
	if err := f.Close(); err != nil {
		return err
	}
	return os.Rename(tmp, file)
}

func (e *env) normalize(args []string) error {
	id, err := one(args, "source id")
	if err != nil {
		return err
	}
	s, err := e.reg.Get(id)
	if err != nil {
		return err
	}
	if id != "kcv" {
		return fmt.Errorf("normalize %s: only kcv is implemented (M0)", id)
	}
	if err := os.MkdirAll(filepath.Join(e.work, "norm"), 0o755); err != nil {
		return err
	}
	out := filepath.Join(e.work, "norm", id+".jsonl")
	w, err := norm.Create(out)
	if err != nil {
		return err
	}
	st, err := kcv.Normalize(filepath.Join(e.work, "raw", id), s.LicenseClass, w.Write)
	if cerr := w.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		return err
	}
	slog.Info("normalize", "id", id, "books", st.Books, "poems", st.Poems, "duplicates", st.Duplicates, "lines", st.Lines, "out", out)
	return nil
}

// langSources returns normalized corpora and frequency lists for a language.
func (e *env) langSources(lang string) (corpora, freqs []sources.Source) {
	for _, s := range e.reg {
		if s.Lang != lang {
			continue
		}
		if _, err := os.Stat(filepath.Join(e.work, "norm", s.ID+".jsonl")); err == nil {
			corpora = append(corpora, s)
		} else if s.Kind == "file" && strings.HasPrefix(s.ID, "freqwords-") {
			freqs = append(freqs, s)
		}
	}
	return
}

func (e *env) lexicon(args []string) error {
	lang, err := one(args, "lang")
	if err != nil {
		return err
	}
	fs := flag.NewFlagSet("lexicon", flag.ExitOnError)
	minCorpus := fs.Int("min", 2, "minimal corpus count")
	_ = fs.Parse(args[1:])
	corpora, freqs := e.langSources(lang)
	if len(corpora) == 0 {
		return fmt.Errorf("lexicon %s: no normalized corpus in work/norm", lang)
	}
	c := lexicon.NewCounter()
	for _, s := range corpora {
		if err := norm.Each(filepath.Join(e.work, "norm", s.ID+".jsonl"), func(p *norm.Poem) error {
			c.AddPoem(p)
			return nil
		}); err != nil {
			return err
		}
	}
	freqList, freqTotal := map[string]int{}, 0
	used := append([]sources.Source(nil), corpora...)
	for _, s := range freqs {
		f, err := os.Open(filepath.Join(e.work, "raw", s.ID, path.Base(s.URL)))
		if err != nil {
			return fmt.Errorf("frequency list %s missing, run rymo fetch %s: %w", s.ID, s.ID, err)
		}
		m, total, err := lexicon.ReadFrequencyWords(f)
		f.Close()
		if err != nil {
			return err
		}
		for k, v := range m {
			freqList[k] += v
		}
		freqTotal += total
		used = append(used, s)
	}
	entries := lexicon.Build(c, freqList, freqTotal, *minCorpus)
	dir := filepath.Join(e.work, lang)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	if err := lexicon.WriteTSV(filepath.Join(dir, "lexicon.tsv"), entries); err != nil {
		return err
	}
	sj, _ := json.MarshalIndent(used, "", "  ")
	if err := os.WriteFile(filepath.Join(dir, "sources.json"), sj, 0o644); err != nil {
		return err
	}
	slog.Info("lexicon", "lang", lang, "words", len(entries), "freq_lists", len(freqs))
	return nil
}

func (e *env) pairs(args []string) error {
	lang, err := one(args, "lang")
	if err != nil {
		return err
	}
	fs := flag.NewFlagSet("pairs", flag.ExitOnError)
	golden := fs.Int("golden", 20000, "golden sample size")
	year := fs.Int("year", time.Now().Year(), "current year for the public-domain rule")
	_ = fs.Parse(args[1:])
	corpora, _ := e.langSources(lang)
	dir := filepath.Join(e.work, lang)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	var x *pairs.Extractor
	for _, s := range corpora {
		if x == nil {
			x = pairs.NewExtractor(pairs.Options{CiteText: s.CiteText, CurrentYear: *year})
		}
		if err := norm.Each(filepath.Join(e.work, "norm", s.ID+".jsonl"), func(p *norm.Poem) error {
			x.AddPoem(p)
			return nil
		}); err != nil {
			return err
		}
	}
	if x == nil {
		return fmt.Errorf("pairs %s: no normalized corpus", lang)
	}
	for _, step := range []func() error{
		func() error { return x.WritePairs(filepath.Join(dir, "pairs.tsv")) },
		func() error { return x.WriteCites(filepath.Join(dir, "cites.tsv")) },
		func() error { return x.WriteGolden(filepath.Join(dir, "golden.tsv"), *golden, 2026) },
	} {
		if err := step(); err != nil {
			return err
		}
	}
	np, occ, nc := x.Stats()
	slog.Info("pairs", "lang", lang, "pairs", np, "occurrences", occ, "cite_candidates", nc)
	return nil
}

func (e *env) dart(args ...string) error {
	return run(filepath.Join(e.root, "packages", "rymo_core"), "dart", append([]string{"run"}, args...)...)
}

func (e *env) pack(args []string) error {
	lang, err := one(args, "lang")
	if err != nil {
		return err
	}
	dir := filepath.Join(e.work, lang)
	a := []string{"rymo_core:build_pack", "--lang", lang, "--dir", dir, "--out", filepath.Join(dir, lang+".rpack")}
	if exc := filepath.Join(e.root, "pipeline", "data", "exc_"+lang+".tsv"); fileExists(exc) {
		a = append(a, "--exc", exc)
	}
	extra := args[1:]
	if len(extra) == 0 {
		extra = packLevers[lang]
	}
	return e.dart(append(a, extra...)...)
}

func (e *env) eval(args []string) error {
	lang, err := one(args, "lang")
	if err != nil {
		return err
	}
	dir := filepath.Join(e.work, lang)
	return e.dart("rymo_core:eval", "--pack", filepath.Join(dir, lang+".rpack"), "--dir", dir,
		"--out", filepath.Join(e.root, "docs", "eval_"+lang+".md"))
}

func (e *env) release(args []string) error {
	lang, err := one(args, "lang")
	if err != nil {
		return err
	}
	fs := flag.NewFlagSet("release", flag.ExitOnError)
	research := fs.Bool("research", false, "allow nc/unknown sources (never publish)")
	version := fs.Int("version", 1, "pack version")
	base := fs.String("base-url", "https://github.com/lioilsources/rymomat-packs/releases/download", "release asset base URL")
	_ = fs.Parse(args[1:])
	dir := filepath.Join(e.work, lang)
	var srcs []sources.Source
	b, err := os.ReadFile(filepath.Join(dir, "sources.json"))
	if err != nil {
		return fmt.Errorf("release: %w (run rymo lexicon first)", err)
	}
	if err := json.Unmarshal(b, &srcs); err != nil {
		return err
	}
	ent, err := release.Build(release.Options{Lang: lang, PackPath: filepath.Join(dir, lang+".rpack"), OutDir: filepath.Join(e.work, "release"),
		BaseURL: *base, Version: *version, Schema: 1, Sources: srcs, Research: *research})
	if err != nil {
		return err
	}
	slog.Info("release", "lang", lang, "zip_bytes", ent.Size, "unpacked", ent.Unpacked, "sha256", ent.SHA256)
	return nil
}

// packLevers are the budget levers (plan §7) a language needs to fit the
// budget; measured in docs/M0_REPORT.md. Explicit arguments replace them.
var packLevers = map[string][]string{
	"cs": {"--no-as-index", "--max-partners", "30", "--max-cites", "100000"},
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

func run(dir, name string, args ...string) error {
	c := exec.Command(name, args...)
	c.Dir = dir
	c.Stdout, c.Stderr = os.Stdout, os.Stderr
	if err := c.Run(); err != nil {
		return fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	return nil
}
