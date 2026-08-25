package task

import (
	"testing"
)

func TestParseDate(t *testing.T) {
	d, err := ParseDate("2026-08-26")
	if err != nil {
		t.Fatalf("ParseDate: %v", err)
	}
	if d.UTC().Format("2006-01-02") != "2026-08-26" {
		t.Fatalf("ParseDate: got %v", d)
	}
	if _, err := ParseDate("not-a-date"); err == nil {
		t.Fatal("ParseDate should reject invalid input")
	}
	if _, err := ParseDate("2026-13-01"); err == nil {
		t.Fatal("ParseDate should reject invalid month")
	}
}

func TestParseDateLike(t *testing.T) {
	cases := []string{"2026-08-26", "2026-08-26T00:00:00Z", "2026-08-26T21:00:00+03:00"}
	for _, c := range cases {
		d, err := ParseDateLike(c)
		if err != nil {
			t.Fatalf("ParseDateLike(%q): %v", c, err)
		}
		if d == nil {
			t.Fatalf("ParseDateLike(%q): nil", c)
		}
	}
	if _, err := ParseDateLike("garbage"); err == nil {
		t.Fatal("ParseDateLike should reject invalid input")
	}
}

func TestTaskValidTimezone(t *testing.T) {
	base := Task{Name: "x", Duration: 30, PreferredStart: 540, Priority: 2}
	if err := base.Valid(); err != nil {
		t.Fatalf("valid base rejected: %v", err)
	}
	bad := base
	bad.Timezone = "Not/AZone"
	if err := bad.Valid(); err == nil {
		t.Fatal("invalid timezone should be rejected")
	}
	good := base
	good.Timezone = "Europe/Sofia"
	if err := good.Valid(); err != nil {
		t.Fatalf("valid timezone rejected: %v", err)
	}
}
