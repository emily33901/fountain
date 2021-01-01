module main

// import sokol.gfx
import gg
import gx
import sokol.sapp
import sokol.sgl

const (
	win_width  = 600
	win_height = 700
	bg_color   = gx.white
)

[console]
fn main() {
	mut font := new_font(height: 20, face_name: 'Tahoma') or { panic('failed to create font') }

	font.glyph(`c`)
}


