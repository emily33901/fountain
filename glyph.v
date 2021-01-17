module main

struct Metrics {
pub:
	// The A spacing of the character.
	// The A spacing is the distance to add to the current position 
	// before drawing the character glyph.
	a int
	// The B spacing of the character.
	// The B spacing is the width of the drawn portion of the character glyph.
	b int
	// The C spacing of the character.
	// The C spacing is the distance to add to the current position 
	// to provide white space to the right of the character glyph.
	c int
} 

pub fn (m Metrics) total_size() int {
	return m.a + m.b + m.c
}

struct GlyphData {
pub:
	metrics Metrics
	data    []byte
}

pub fn (g GlyphData) total_size() int {
	return g.metrics.a + g.metrics.b + g.metrics.c
}
