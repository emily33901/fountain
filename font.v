module main

interface Font {
	metrics(ch rune) ?Metrics
	glyph_data(ch rune) ?GlyphData
	channels() int
	kern(ch1 rune, ch2 rune) int
}

fn coerce_font(f Font) Font {
	return f
}
