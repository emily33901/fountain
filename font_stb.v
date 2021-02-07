module main

import os

// #flag -DSTBTT_malloc=main__tmpalloc
// #flag -DSTBTT_free=main__tmpfree
#flag -DSTBTT_STATIC
#flag -DSTB_TRUETYPE_IMPLEMENTATION

#include "@VROOT/stb_truetype.h"

[typedef]
struct C.stbtt__buf {}

struct C.stbtt_fontinfo {
pub mut:
	userdata voidptr
	data voidptr
	fontstart int

	numGlyphs int
	loca int
	head int
	glyf int
	hhea int
	hmtx int
	kern int
	gpos int
	svg int 
	index_map int
	indexToLocFormat int
	cff stbtt__buf 
	charstrings stbtt__buf 
	gsubrs stbtt__buf 
	subrs stbtt__buf 
	fontdicts stbtt__buf 
	fdselect stbtt__buf 
}

fn tmpalloc(size int, mut font StbFont) voidptr {
	return unsafe {
		malloc(size)
	}
}

fn tmpfree(ptr voidptr, mut font StbFont) {
	unsafe {
		free(ptr)
	}
}

fn C.stbtt_InitFont() bool
fn C.stbtt_GetFontVMetrics()
fn C.stbtt_ScaleForPixelHeight() f32
fn C.stbtt_GetCodepointHMetrics()
fn C.stbtt_GetCodepointBitmapBox()
fn C.stbtt_MakeCodepointBitmap()
fn C.stbtt_GetCodepointKernAdvance() int
fn C.stbtt_GetFontBoundingBox()

// Stb truetype font
struct StbFont {
pub mut:
	info C.stbtt_fontinfo
	scale f32
	ascent int
	descent int
	line_gap int
	max_width int
	max_height int
	cache   MetricsCache

	bitmap []byte
	bitmap_width int
	bitmap_height int

	scratch []byte
}

struct StbFontConfig {
	font_file_name string
	height int
}

pub fn new_stb_font(config StbFontConfig) ?Font {
	// read font file out into a buffer
	font_bytes := os.read_bytes(config.font_file_name)?

	mut font := &StbFont {
		cache: new_metrics_cache(1000)
	}

	// pass them to stb
	if !C.stbtt_InitFont(&font.info, font_bytes.data, 0) {
		return error('Couldnt initialise font')
	}

	font.scale = C.stbtt_ScaleForPixelHeight(&font.info, config.height)

	C.stbtt_GetFontVMetrics(&font.info, &font.ascent, &font.descent, &font.line_gap)

	println('$font.line_gap')
	font.line_gap = int(font.line_gap * font.scale)

	println('$font.ascent $font.descent')
	
	{
		x := 0
		y := 0
		u := 0
		v := 0
		C.stbtt_GetFontBoundingBox(&font.info, &x, &y, &u, &v)

		font.max_width = int((u - x) * font.scale)
		font.max_height = int((v - y) * font.scale)
	}

	font.bitmap = []byte{ len: font.max_width * font.max_height, init: 0 }
	font.info.userdata = font

	return coerce_font(font)
}

pub fn (mut f StbFont) metrics(ch rune) ?Metrics {
	if metrics := f.cache.get(ch) {
		return metrics
	}

	advance := 0
	left_side := 0

	x := 0
	y := 0
	u := 0
	v := 0

	C.stbtt_GetCodepointHMetrics(&f.info, ch, &advance, &left_side)
	C.stbtt_GetCodepointBitmapBox(&f.info, ch, f.scale, f.scale, &x, &y, &u, &v)

	m := Metrics {
		// a is the left_side
		a: int(left_side * f.scale)

		// b is advance - left_side
		b: int((advance - left_side) * f.scale)

		// stb doesnt have c
		c: 0

		// TODO this name is wrong please pick a better one :)
		ascent: int(((f.ascent) * f.scale) + y)

		width: (u - x)
		height: (v - y)
		line_space: f.line_gap - int(f.descent * f.scale)
	}

	f.cache.add(ch, m)
	return m
}

pub fn (mut f StbFont) glyph_data(ch rune) ?GlyphData {
	metrics := f.metrics(ch)?

	unsafe {
		C.memset(f.bitmap.data, 0, f.bitmap.len)
	}

	C.stbtt_MakeCodepointBitmap(&f.info, f.bitmap.data, metrics.width, metrics.height, f.max_width, f.scale, f.scale, ch)

	return GlyphData {
		metrics: metrics
		data: f.bitmap
	}
}

pub fn (mut f StbFont) channels() int {
	return 1
}

pub fn (mut f StbFont) kern(ch1 rune, ch2 rune) int {
	return int(C.stbtt_GetCodepointKernAdvance(&f.info, ch1, ch2) * f.scale)
}

pub fn (mut f StbFont) max_width() int {
	return f.max_width
}

pub fn (mut f StbFont) max_height() int {
	return f.max_height
}
