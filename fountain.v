module main

import gg
import gx
import sokol.sapp
import sokol.sgl

const (
	win_width  = 600
	win_height = 700
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

struct Glyph {
	GlyphData
mut:
	image C.sg_image
}

struct App {
mut:
	made_image bool
	font       Font
	gs         []Glyph
	gg         &gg.Context
	ready      bool
}

fn init(mut app App) {
	for mut g in app.gs {
		mut img_desc := C.sg_image_desc{
			width: app.font.width
			height: app.font.height
			num_mipmaps: 0
			min_filter: .linear
			mag_filter: .linear
			//*****************************************
			// usage: .dynamic        // DECOMENT THIS CRASH THE PROGRAM
			//*****************************************
			usage: .immutable
			wrap_u: .clamp_to_edge
			wrap_v: .clamp_to_edge
			label: &byte(0)
			d3d11_texture: 0
		}
		img_desc.content.subimage[0][0] = C.sg_subimage_content{
			ptr: g.data.data
			size: g.data.len
		}
		g.image = C.sg_make_image(&img_desc)
	}
	app.ready = true
}

fn draw_frame(mut app App) {
	if !app.ready {
		return
	}
	app.gg.begin()
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(sapp.width()), f32(sapp.height()), 0.0, -1.0, 1.0)
	sgl.c4b(0, 0, 0, 128) // black
	mut offset := 10
	mut y_offset := 10
	mut i := 0
	for glyph in app.gs {
		draw_image(app.gg, offset, y_offset, app.font.width, app.font.height, glyph.image)
		offset += glyph.total_size()
		i++
		if i % 10 == 0 {
			y_offset += app.font.ascent
			offset = 10
		}
	}
	app.gg.end()
}

[console]
fn main() {
	mut font := new_font(height: 100, face_name: 'Tahoma') or { panic('failed to create font') }
	chars := [
		`㈀`,
		`㈁`,
		`㈂`,
		`㈃`,
		`㈄`,
		`㈅`,
		`㈆`,
		`㈇`,
		`㈈`,
		`㈉`,
		`㈊`,
		`㈋`,
		`㈌`,
		`㈍`,
		`㈎`,
		`㈏`,
		`㈐`,
		`㈑`,
		`㈒`,
		`㈓`,
		`㈔`,
		`㈕`,
		`㈖`,
		`㈗`,
		`㈘`,
		`㈙`,
		`㈚`,
		`㈛`,
		`㈜`,
		`㈠`,
		`㈡`,
		`㈢`,
		`㈣`,
		`㈤`,
		`㈥`,
		`㈦`,
		`㈧`,
		`㈨`,
		`㈩`,
		`㈪`,
		`㈫`,
		`㈬`,
		`㈭`,
		`㈮`,
		`㈯`,
		`㈰`,
		`㈱`,
		`㈲`,
		`㈳`,
		`㈴`,
		`㈵`,
		`㈶`,
		`㈷`,
		`㈸`,
		`㈹`,
		`㈺`,
		`㈻`,
		`㈼`,
		`㈽`,
		`㈾`,
		`㈿`,
		`㉀`,
		`㉁`,
		`㉂`,
		`㉃`,
		`㉠`,
		`㉡`,
		`㉢`,
		`㉣`,
		`㉤`,
		`㉥`,
		`㉦`,
		`㉧`,
		`㉨`,
		`㉩`,
		`㉪`,
		`㉫`,
		`㉬`,
		`㉭`,
		`㉮`,
		`㉯`,
		`㉰`,
		`㉱`,
		`㉲`,
		`㉳`,
		`㉴`,
		`㉵`,
		`㉶`,
		`㉷`,
		`㉸`,
		`㉹`,
		`㉺`,
		`㉻`,
		`㉿`,
		`㊀`,
		`㊁`,
		`㊂`,
		`㊃`,
		`㊄`,
		`㊅`,
		`㊆`,
		`㊇`,
		`㊈`,
		`㊉`,
		`㊊`,
		`㊋`,
		`㊌`,
		`㊍`,
		`㊎`,
		`㊏`,
		`㊐`,
		`㊑`,
		`㊒`,
		`㊓`,
		`㊔`,
		`㊕`,
		`㊖`,
		`㊗`,
		`㊘`,
		`㊙`,
		`㊚`,
		`㊛`,
		`㊜`,
		`㊝`,
		`㊞`,
		`㊟`,
		`㊠`,
		`㊡`,
	]
	mut gs := []Glyph{cap: chars.len}
	for c in chars {
		data := font.glyph_data(rune(c)) or {
			panic('Cant render this character')
			return
		}
		g := Glyph{
			GlyphData: data
		}
		gs << g
	}
	// test := gs[5]
	// for i := 0; i < test.data.len; i += 4 {
	// 	if i % (font.width*4) == 0 {
	// 		println('')
	// 	}
	// 	if test.data[i+3] > 0 {
	// 		print('x')
	// 	} else {
	// 		print(' ')
	// 	}
	// }
	mut a := &App{
		font: font
		gs: gs
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
