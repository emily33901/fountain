module main

import gg
import gx
import sokol.sapp
import sokol.sgl
import rand
import os

import util

const (
	win_width  = 1280
	win_height = 720
)

fn draw_image(ctx &gg.Context, x f32, y f32, width f32, height f32, sg_img &C.sg_image) {
	u0 := f32(0.0)
	v0 := f32(0.0)
	u1 := f32(1.0)
	v1 := f32(1.0)
	x0 := f32(x) * ctx.scale
	y0 := f32(y) * ctx.scale
	x1 := f32(x + width) * ctx.scale
	mut y1 := f32(y + height) * ctx.scale
	/*
	if height == 0 {
		scale := f32(img.width) / f32(width)
		y1 = f32(y + int(f32(img.height) / scale)) * ctx.scale
	}
	*/
	//
	sgl.load_pipeline(ctx.timage_pip)
	sgl.enable_texture()
	sgl.texture(sg_img)
	sgl.begin_quads()
	sgl.c4b(255, 255, 255, 255)
	sgl.v2f_t2f(x0, y0, u0, v0)
	sgl.v2f_t2f(x1, y0, u1, v0)
	sgl.v2f_t2f(x1, y1, u1, v1)
	sgl.v2f_t2f(x0, y1, u0, v1)
	sgl.end()
	sgl.disable_texture()
}

struct App {
mut:
	font       Font
	gg         &gg.Context
	cache      util.TextureCache
	frame      int
	text ustring
	ready      bool
}

fn init(mut app App) {
	app.cache = util.new_texture_cache(4000, 4000)

	app.ready = true
}

fn draw_frame(mut app App) {
	if !app.ready {
		return
	}
	app.frame++
	app.gg.begin()
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(sapp.width()), f32(sapp.height()), 0.0, -1.0, 1.0)
	sgl.c4b(0, 0, 0, 128) // black

	// load some more glyphs
	mut misses := 0
	for i := 0; i < 100; i++ {
		s := app.text.at(rand.intn(app.text.len))
		ch := rune(s.utf32_code())

		unsafe {
			s.free()
		}

		_ := app.cache.get(ch) or {
			misses++
			glyph_data := app.font.glyph_data(ch) or {
				panic('Unable to get glyph data')
			}

			new_slot := app.cache.add(ch, app.font.width, app.font.height, glyph_data.data)

			unsafe {
				glyph_data.data.free()
			}

			new_slot
		}
	}
	// update the texture
	app.cache.flush()

	draw_image(app.gg, 0, 0, app.cache.atlas.width, app.cache.atlas.height, app.cache.atlas.texture)

	println('miss: $misses')

	app.gg.end()
}

[console]
fn main() {
	mut font := new_font(height: 50, face_name: 'Tahoma') or { panic('failed to create font') }

	text := os.read_file('unicode.txt')?
	ustr := text.ustring()

	mut a := &App{
		text: ustr
		font: font
		gg: voidptr(0)
	}
	a.gg = gg.new_context(
		width: win_width
		height: win_height
		use_ortho: true
		create_window: true
		window_title: 'test test test'
		user_data: a
		bg_color: gx.black
		frame_fn: draw_frame
		init_fn: init
	)
	a.gg.run()
}
