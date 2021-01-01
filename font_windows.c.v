module main

fn C.GetTextMetrics() bool

struct Font {
mut:
	context DrawContext
	handle  Handle
	bitmap  Bitmap
	width   int
	height  int
	ascent  int
	cache LruCache
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
	quality          u32 = antialiased_quality
	pitch_and_family u32 = default_pitch | ff_dontcare
	face_name        string
}

fn new_font(config FontConfig) ?Font {
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
	tm := C.TEXTMETRICW{}
	if !C.GetTextMetrics(dc, &tm) {
		// failed to get metrics so we have no idea what the sizes
		// are which is pretty useless
		return none
	}
	mut new_font := Font{
		context: dc
		height: tm.tmHeight
		width: tm.tmMaxCharWidth
		ascent: tm.tmAscent
		handle: font_handle
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


fn (mut f Font) metrics(ch rune) ?Metric {
	if cached := f.cache.get(ch) {
		return cached.metric
	}

	// we dont have a cached version
	// so go get it now

	// first try GetCharWidth32W
	// then try GetCharABCWidthsW
	m := Metric{}
	if C.GetCharABCWidthsW(f.context, ch, ch, &m) {
		return m
	}
	if C.GetCharWidth32W(f.context, ch, ch, &m) {
		return m
	}

	return none
}

fn (mut f Font) glyph(ch rune) ?Glyph {
	if cached := f.cache.get(ch) {
		return cached
	}
	metrics := f.metrics(ch)?

	// make sure our font is active
	C.SelectObject(f.context, f.handle)
	
	wide := metrics.b
	tall := f.height

	mat := default_mat2()
	glyph_metrics := GlyphMetrics{}

	println('$ch ${int(ch)}')
	ch16 := u16(ch)
	bytes_needed := C.GetGlyphOutlineW(f.context, ch16, ggo_gray8_bitmap, &glyph_metrics, 0, C.NULL, &mat)
	println('$bytes_needed')

	if bytes_needed > 0 {
		// TODO does this ever happen?
		panic('This path is not implemented yet...')
	} else {
		// render to bitmap and use that
		C.SetBkColor(f.context, 0)
		C.SetTextColor(f.context, -1)
		C.SetBkMode(f.context, opaque)

		// draw the character
		C.MoveToEx(f.context, -metrics.a, 0, C.NULL)
		C.ExtTextOutW(f.context, 0, 0, 0, 0, C.NULL, &ch16, 1, C.NULL)

		C.SetBkMode(f.context, transparent)
	}

	return none
}
