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
