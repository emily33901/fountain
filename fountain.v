module main

import gg
import gx
import sokol.sapp
import sokol.sgl
import rand
import os
import encoding.utf8
import math

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
	frame      int
	text       string
	ready      bool
	renderer   SokolRender

	key_down bool
	show_tex_map bool
	cur_tex_page int

	first_line int
	newline_pos []int
}

fn init(mut app App) {
	app.renderer = new_sokol_render(app.font)
	app.ready = true
}

fn C.alloca()

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

	if !app.key_down { // && app.frame % 4 == 0 {
		app.first_line += 10
		// app.first_line++
	}
	
	misses_text := 'Misses: ${app.renderer.cache.cache_misses()}'
	println('${app.renderer.cache.cache_misses()}')
	app.renderer.draw_text_on_texture(app.gg, misses_text, 400, 0, sapp.width(), sapp.height()) or {
		panic('cannot draw text')
	}
	
	scrolling_text := if !app.key_down {
		'Scrolling'
	} else {
		'Paused'
	}

	app.renderer.draw_text_on_texture(app.gg, scrolling_text, 100, 0, sapp.width(), sapp.height()) or {
		panic('cannot draw text')
	}

	defer {
		unsafe {
			misses_text.free()
			scrolling_text.free()
		}
	}

	if !app.show_tex_map {
		para_text := app.text[app.newline_pos[app.first_line % app.newline_pos.len] .. app.text.len]
		app.renderer.draw_text_on_texture(app.gg, para_text, app.font.max_height(), 20, sapp.width(), sapp.height()) or {
			panic('Failed to draw text!')
		}

		unsafe { para_text.free() }
	} else {
		// show the texture map
		cur_page := int(math.abs(app.cur_tex_page % app.renderer.cache.atlas.pages.len))
		page := app.renderer.cache.atlas.pages[cur_page]
		draw_image(app.gg, app.font.max_width(), 0, page.width, page.height, page.texture)

		page_number := '$cur_page'
		app.renderer.draw_text_on_texture(app.gg, page_number, 0, 0, sapp.width(), sapp.height()) or {
			panic('Failed to draw text!')
		}

		unsafe {
			page_number.free()
		}
	}

	// update the cache
	app.renderer.cache.flush()

	app.gg.end()
}

fn key_down(code sapp.KeyCode, modifier sapp.Modifier, mut app App) {
	println('$code')

	match code {
		.m {
			app.show_tex_map = !app.show_tex_map
		}
		
		.left {
			app.cur_tex_page--
		}

		.right {
			app.cur_tex_page++
		}

		else {
			app.key_down = !app.key_down
		}
	}

}

[console]
fn main() {
	// mut font := new_gdi_font(height: 30, face_name: 'Tahoma') or { panic('failed to create font') }
	// mut font := new_stb_font(height: 24, font_file_name: 'ttf/Graduate-Regular.ttf')?
	// mut font := new_stb_font(height: 24, font_file_name: 'C:/Windows/Fonts/Tahoma.ttf')?
	mut font := new_stb_font(height: 10, font_file_name: 'ttf/mononoki-Regular.ttf')?

	// precache the newlines to make our test easier
	text := os.read_file('text/macbeth.txt')?
	// ustr := text.ustring()

	mut newline_pos := [0]

	for i := 0; i < text.len; i++ {
		// see if we are dealing with a unicode char
		b := text[i]
		ch_len := ((0xe5000000>>((b>>3) & 0x1e)) & 3)
		
		ch := if ch_len > 0 {
			i += ch_len
			rune(utf8.get_uchar(text,i-ch_len))
		} else {
			rune(b)
		}

		if ch == `\n` {
			newline_pos << i+1
		}
	}

	mut a := &App{
		text: text
		font: font
		gg: voidptr(0)

		newline_pos: newline_pos
		first_line: 0
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
		keydown_fn: key_down
		init_fn: init
	)
	a.gg.run() 
}
