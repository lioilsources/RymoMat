// Package sources loads the source registry and enforces the license gate.
package sources

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Source is one entry of sources.yaml.
type Source struct {
	ID           string `yaml:"id" json:"id"`
	Kind         string `yaml:"kind" json:"kind"`
	URL          string `yaml:"url" json:"url"`
	Lang         string `yaml:"lang" json:"lang"`
	License      string `yaml:"license" json:"license"`
	LicenseClass string `yaml:"license_class" json:"license_class"`
	Attribution  string `yaml:"attribution" json:"attribution"`
	CiteText     bool   `yaml:"cite_text" json:"cite_text"`
}

// Registry is the parsed sources.yaml.
type Registry []Source

// Load reads a registry file.
func Load(path string) (Registry, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var r Registry
	if err := yaml.Unmarshal(b, &r); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	for _, s := range r {
		switch s.LicenseClass {
		case "pd", "by-sa", "nc", "unknown":
		default:
			return nil, fmt.Errorf("source %s: invalid license_class %q", s.ID, s.LicenseClass)
		}
	}
	return r, nil
}

// Get returns the source with the given id.
func (r Registry) Get(id string) (Source, error) {
	for _, s := range r {
		if s.ID == id {
			return s, nil
		}
	}
	return Source{}, fmt.Errorf("unknown source %q", id)
}

// Gate fails when any source is nc or unknown, unless research is set.
func Gate(srcs []Source, research bool) error {
	if research {
		return nil
	}
	for _, s := range srcs {
		if s.LicenseClass == "nc" || s.LicenseClass == "unknown" {
			return fmt.Errorf("license gate: source %s has license_class %s (use --research for non-release builds)", s.ID, s.LicenseClass)
		}
	}
	return nil
}
