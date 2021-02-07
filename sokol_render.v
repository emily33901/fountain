module main

import util
import gg
import encoding.utf8

import sokol.sgl

struct SokolRender {
pub mut:
	font       Font
	cache      util.TextureCache
}

fn new_sokol_render(f Font) SokolRender {
	channels := f.channels()
	return SokolRender{
		font: f
		cache: util.new_texture_cache(f.max_width(), f.max_height(), channels)
	}
}

[inline]
fn (mut s SokolRender) glyph(ch rune) util.Slot {
	slot := s.cache.get(ch) or {
		glyph_data := s.font.glyph_data(ch) or {
			panic('Unable to get glyph data')
		}

		// we dont need to free glyph_data.data here becuase it refers to the bitmap
		// we allocated from windows
		s.cache.add(ch, glyph_data.metrics.width, glyph_data.metrics.height, s.font.max_width(), glyph_data.data)
	}

	return slot
}

fn (r SokolRender) draw_image(ctx &gg.Context, s util.Slot, dest_x int, dest_y int) {
	u0 := s.tx
	v0 := s.ty
	u1 := s.tu
	v1 := s.tv

	x0 := f32(dest_x) * ctx.scale
	y0 := f32(dest_y) * ctx.scale
	x1 := f32(dest_x + (s.u-s.x)) * ctx.scale
	mut y1 := f32(dest_y + (s.v-s.y)) * ctx.scale

	sgl.texture(s.page.texture)
	sgl.begin_quads()
	sgl.c4b(255, 255, 255, 255)
	sgl.v2f_t2f(x0, y0, u0, v0)
	sgl.v2f_t2f(x1, y0, u1, v0)
	sgl.v2f_t2f(x1, y1, u1, v1)
	sgl.v2f_t2f(x0, y1, u0, v1)
	sgl.end()
}

pub fn (mut s SokolRender) draw_text_on_texture(ctx &gg.Context, text string, initial_x int, initial_y int, width int, height int) ? {
	mut x := initial_x
	mut y := initial_y

	sgl.load_pipeline(ctx.timage_pip)
	sgl.enable_texture()

	defer {
		sgl.disable_texture()
	}

	mut last_char := rune(0)
	
	for i := 0; i < text.len; i++ {
		b := text[i]
		// see if we are dealing with a unicode char
		ch_len := ((0xe5000000>>((b>>3) & 0x1e)) & 3)
		
		ch := if ch_len > 0 {
			i += ch_len
			rune(utf8.get_uchar(text, i-ch_len))
		} else {
			rune(b)
		}

		metrics := s.font.metrics(ch)?

		// if we hit a newline then deal with it 
		if ch == `\n` || x + metrics.total_size() > width {
			x = initial_x
			y += metrics.height + metrics.line_space + metrics.ascent
			if y > height {
				return
			}

			continue
		}

		x += metrics.a + if last_char != 0 {
			s.font.kern(last_char, ch)
		} else {
			0
		}
		real_y := y + metrics.ascent
		glyph_slot := s.glyph(ch)
		s.draw_image(ctx, glyph_slot, x, real_y)
		x += metrics.b + metrics.c

		last_char = ch
	}
}

fn (mut s SokolRender) draw_text(ctx &gg.Context, text string, width int, height int) ? { // } ?C.sg_image {
	// tex_desc := C.sg_image_desc {
	// 	width: width
	// 	height: height
	// 	render_target: true
	// 	num_mipmaps: 0
	// 	min_filter:   .linear
    // 	mag_filter:   .linear
	// 	usage: .dynamic
	// 	wrap_u: .clamp_to_edge
	// 	wrap_v: .clamp_to_edge
	// }

	// tex := C.sg_make_image(&tex_desc)
	s.draw_text_on_texture(ctx, text, 0, 0, width, height)?

	// return tex
}
