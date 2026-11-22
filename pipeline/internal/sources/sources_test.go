package sources

import "testing"

func TestGateRejectsNonCommercial(t *testing.T) {
	ok := []Source{{ID: "kcv", LicenseClass: "by-sa"}, {ID: "pd", LicenseClass: "pd"}}
	if err := Gate(ok, false); err != nil {
		t.Fatal(err)
	}
	for _, lc := range []string{"nc", "unknown"} {
		bad := append(ok, Source{ID: "x", LicenseClass: lc})
		if err := Gate(bad, false); err == nil {
			t.Errorf("%s source passed the gate", lc)
		}
		if err := Gate(bad, true); err != nil {
			t.Errorf("research build failed: %v", err)
		}
	}
}

func TestRegistry(t *testing.T) {
	r, err := Load("../../sources.yaml")
	if err != nil {
		t.Fatal(err)
	}
	s, err := r.Get("kcv")
	if err != nil || s.LicenseClass != "by-sa" || !s.CiteText {
		t.Fatalf("kcv = %+v, %v", s, err)
	}
	fr, _ := r.Get("poetree-fr")
	if Gate([]Source{fr}, false) == nil {
		t.Error("poetree-fr must be rejected")
	}
}
