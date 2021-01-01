#flag windows -lgdi32
type Handle = voidptr

type DrawContext = voidptr

fn C.CreateFontA() Handle

fn C.CreateCompatibleDC() DrawContext

fn C.EnumFontFamiliesEx() int

fn C.SetMapMode()

fn C.SelectObject()

fn C.SetTextAlign()

const (
	_space = 0
)

[typedef]
struct C.TEXTMETRICW {
	tmHeight           int
	tmAscent           int
	tmDescent          int
	tmInternalLeading  int
	tmExternalLeading  int
	tmAveCharWidth     int
	tmMaxCharWidth     int
	tmWeight           int
	tmOverhang         int
	tmDigitizedAspectX int
	tmDigitizedAspectY int
	tmFirstChar        u16
	tmLastChar         u16
	tmDefaultChar      u16
	tmBreakChar        u16
	tmItalic           byte
	tmUnderlined       byte
	tmStruckOut        byte
	tmPitchAndFamily   byte
	tmCharSet          byte
}

struct C.LOGFONTW {
	height           u32
	width            u32
	escapement       u32
	orientation      u32
	weight           u32
	italic           byte
	underline        byte
	strikeout        u32
	charset          byte
	precision        byte
	clip_precision   byte
	pitch_and_family byte
	// unicode font name
	face_name        [32]u16
}

[typedef]
struct C.BITMAPINFOHEADER {
	biSize          u32
	biWidth         int
	biHeight        int
	biPlanes        i16
	biBitCount      i16
	biCompression   int
	biSizeImage     u32
	biXPelsPerMeter int
	biYPelsPerMeter int
	biClrUsed       u32
	biClrImportant  u32
}

const (
	out_default_precis   = 0
	out_string_precis    = 1
	out_character_precis = 2
	out_stroke_precis    = 3
	out_tt_precis        = 4
	out_device_precis    = 5
	out_raster_precis    = 6
	out_tt_only_precis   = 7
	out_outline_precis   = 8
)

const (
	clip_default_precis   = 0
	clip_character_precis = 1
	clip_stroke_precis    = 2
	clip_mask             = 15
	clip_lh_angles        = 16
	clip_tt_always        = 32
	clip_embedded         = 128
)

const (
	ansi_charset        = 0
	default_charset     = 1
	symbol_charset      = 2
	shiftjis_charset    = 128
	hangeul_charset     = 129
	hangul_charset      = 129
	gb2312_charset      = 134
	chinesebig5_charset = 136
	greek_charset       = 161
	turkish_charset     = 162
	hebrew_charset      = 177
	arabic_charset      = 178
	baltic_charset      = 186
	russian_charset     = 204
	thai_charset        = 222
	easteurope_charset  = 238
	oem_charset         = 255
	johab_charset       = 130
	vietnamese_charset  = 163
	mac_charset         = 77
)

const (
	default_pitch  = 0
	fixed_pitch    = 1
	variable_pitch = 2
	mono_font      = 8
	ff_decorative  = 80
	ff_dontcare    = 0
	ff_modern      = 48
	ff_roman       = 16
	ff_script      = 64
	ff_swiss       = 32
)

const (
	fw_dontcare   = 0
	fw_thin       = 100
	fw_extralight = 200
	fw_ultralight = fw_extralight
	fw_light      = 300
	fw_normal     = 400
	fw_regular    = 400
	fw_medium     = 500
	fw_semibold   = 600
	fw_demibold   = fw_semibold
	fw_bold       = 700
	fw_extrabold  = 800
	fw_ultrabold  = fw_extrabold
	fw_heavy      = 900
	fw_black      = fw_heavy
)

const (
	default_quality        = 0
	draft_quality          = 1
	proof_quality          = 2
	nonantialiased_quality = 3
	antialiased_quality    = 4
)

const (
	mm_text        = 1
	ta_left        = 0
	ta_top         = 0
	ta_updatecp    = 1
	bi_rgb         = 0
	dib_rgb_colors = 0
)

const (
	spi_getdropshadow            = 0x1024
	spi_getflatmenu              = 0x1022
	spi_getfocusborderheight     = 0x2010
	spi_getfocusborderwidth      = 0x200E
	spi_getfontsmoothingcontrast = 0x200C
	spi_getfontsmoothingtype     = 0x200A
	spi_getmouseclicklock        = 0x101E
	spi_getmouseclicklocktime    = 0x2008
	spi_getmousesonar            = 0x101C
	spi_getmousevanish           = 0x1020
	spi_setdropshadow            = 0x1025
	spi_setflatmenu              = 0x1023
	spi_setfocusborderheight     = 0x2011
	spi_setfocusborderwidth      = 0x200F
	spi_setfontsmoothingcontrast = 0x200D
	spi_setfontsmoothingtype     = 0x200B
	spi_setmouseclicklock        = 0x101F
	spi_setmouseclicklocktime    = 0x2009
	spi_setmousesonar            = 0x101D
	spi_setmousevanish           = 0x1021
)

fn C.SystemParametersInfo()

const (
	spif_updateinifile = 0x0001
	spif_sendchange    = 0x0002
)

fn create_dc() DrawContext {
	return DrawContext(C.CreateCompatibleDC(C.NULL))
}


fn C.GetCharWidth32W() bool

fn C.GetCharABCWidthsW() bool


struct Fixed {
	fract i16
	value i16
}

struct Mat2 {
	a Fixed 
	b Fixed 
	c Fixed 
	d Fixed 
}

fn default_mat2() Mat2 {
	return Mat2 {
		a: {fract: 0, value: 1}
		b: {fract: 0, value: 0}
		c: {fract: 0, value: 0}
		d: {fract: 0, value: 1}
	}
}

const (
	ggo_gray8_bitmap = 8
	opaque  = 2
	transparent = 1
)

fn C.GetGlyphOutlineW() int


struct Point {
	x int
	y int
}

struct GlyphMetrics {
	black_box_x u32
	black_box_y u32
	glyph_origin Point
	cell_x i16
	cell_y i16
}

fn C.SetBkColor()
fn C.SetTextColor()
fn C.SetBkMode()
fn C.ExtTextOutW()
fn C.MoveToEx()


