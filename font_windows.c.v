module main

import os

fn C.GetTextMetrics() bool

struct Font {
mut:
	context DrawContext
	handle  Handle
	bitmap  Bitmap
	width   int
	height  int
	ascent  int
	// glyph cache
	cache   MetricsCache
}

struct FontConfig {
pub:
	height           int
	width            int
	escapement       int
	orientation      int
	weight           int
	italic           bool
	underline        bool
	strikeout        bool
	charset          u32 = default_charset
	out_precision    u32 = out_default_precis
	clip_precision   u32 = clip_default_precis
	quality          u32 = cleartype_quality
	pitch_and_family u32 = default_pitch | ff_dontcare
	face_name        string
}

fn new_font(config FontConfig) ?Font {
	// if !C.SystemParametersInfoW(spi_setfontsmoothing, true, 0, spif_updateinifile | spif_sendchange) {
	// 	println('Failed SystemParametersInfo')
	// 		println('${os.get_error_msg(int(C.GetLastError()))}')
	// }
	// if !C.SystemParametersInfoW(spi_setfontsmoothingtype, true, fe_fontsmoothingcleartype, spif_updateinifile | spif_sendchange) {
	// 	println('Failed SystemParametersInfo 2')
	// 	println('${os.get_error_msg(int(C.GetLastError()))}')
	// }
	dc := create_dc()
	font_handle := Handle(C.CreateFontA(config.height, config.width, config.escapement,
		config.orientation, config.weight, config.italic, config.underline, config.strikeout,
		config.charset, config.out_precision, config.clip_precision, config.pitch_and_family,
		config.quality, config.face_name.str))
	// if the handle is nil then the font isnt valid
	if font_handle == 0 {
		return none
	}
	C.SetMapMode(dc, mm_text)
	C.SelectObject(dc, font_handle)
	C.SetTextAlign(dc, ta_left)
	tm := TextMetrics{}
	if !C.GetTextMetrics(dc, &tm) {
		// failed to get metrics so we have no idea what the sizes
		// are which is pretty useless
		return none
	}
	mut new_font := Font{
		context: dc
		height: tm.height
		width: tm.max_char_width
		ascent: tm.ascent
		handle: font_handle
		cache: new_metrics_cache(1000)
	}
	new_font.create_bitmap() ?
	return new_font
}

fn (mut f Font) create_bitmap() ? {
	f.bitmap = new_bitmap(context: f.context, width: f.width, height: f.height) or {
		return error('Unable to create bitmap')
	}
	f.bitmap.@select()
}

fn (mut f Font) metrics(ch rune) ?Metrics {
	if cached := f.cache.get(ch) {
		return cached
	}
	// we dont have a cached version
	// so go get it now
	// first try GetCharWidth32W
	// then try GetCharABCWidthsW
	m := Metrics{}
	if C.GetCharABCWidthsW(f.context, ch, ch, &m) || C.GetCharWidth32W(f.context, ch, ch, &m) {
		f.cache.add(ch, m)
		return m
	}
	return none
}

fn (mut f Font) glyph_data(ch rune) ?GlyphData {
	metrics := f.metrics(ch) ?
	// make sure our font is active
	C.SelectObject(f.context, f.handle)
	mut wide := f.width
	mut tall := f.height
	// glyph_metrics := WinGlyphMetrics{}
	ch16 := u16(ch)
	C.SetBkColor(f.context, 0)
	C.SetTextColor(f.context, 16777215) // 55 | (255 << 8) | (255 << 16)
	C.SetBkMode(f.context, opaque)
	rect := Rect{0, 0, f.width, f.height}
	// draw the character
	if !C.ExtTextOutW(f.context, 0, 0, opaque, &rect, &ch16, 1, C.NULL) {
		println('failed!')
		println('${os.get_error_msg(int(C.GetLastError()))}')
		return none
	}
	C.SetBkMode(f.context, transparent)
	// copy the glyph from the bitmap
	mut glyph := []byte{len: (wide * tall * 4), init: 0}
	copy(glyph, f.bitmap.data)
	// set the alphas properly
	for i := 0; i < tall * wide * 4; i += 4 {
		r := glyph[i + 0]
		g := glyph[i + 1]
		b := glyph[i + 2]
		glyph[i + 3] = byte((f32(r) * 0.34) + (f32(g) * 0.55) + (f32(b) * 0.11))
	}
	return GlyphData{
		metrics: metrics
		data: glyph
	}
}
