module util

import sokol.sgl
import sokol.gfx

// TODO at some point we are going to need to lock texture slots

struct TextureAtlas {
pub mut:
	pages []Page
	channels int
}

fn new_texture_atlas(width int, height int, channels int, slots int) TextureAtlas {
	mut pages := []Page{len: slots}

	pixel_format := if channels == 4 {
		gfx.PixelFormat.rgba8
	} else if channels == 1 {
		gfx.PixelFormat.r8
	} else {
		panic('Dont know what to do with $channels channels')
		gfx.PixelFormat.@none
	}

	for i := 0; i < slots; i++ {
		tex_desc := C.sg_image_desc {
			width: width
			height: height
			num_mipmaps: 0
			min_filter:   .nearest
			mag_filter:   .nearest
			pixel_format: pixel_format
			usage: .dynamic
			wrap_u: .clamp_to_edge
			wrap_v: .clamp_to_edge
			label: &byte(0)
			d3d11_texture: 0
		}

		pages[i] = Page{
			texture: C.sg_make_image(&tex_desc)
			data: []byte{len: (width * height * channels), init: 0}

			width: width
			height: height
		} 
	}
	
	mut atlas := TextureAtlas {
		pages: pages
		channels: channels
	}

	return atlas
}

fn (mut t TextureAtlas) free() {
	for p in t.pages {
		C.sg_destroy_image(p.texture)
	}
}

fn (mut t TextureAtlas) slot(width int, height int) ?Slot {
	for mut p in t.pages {
		if slot := p.slot(width, height) {
			return slot
		}
	}
	return none
}

[direct_array_access]
fn (mut t TextureAtlas) update(s Slot, data_width int, data_height int, data []byte) {
	if data.len > ((s.u-s.x) * (s.v-s.y) * t.channels) {
		// add another page that is the right size
		println('invalid size so youre going to get garbage')
	}

	page := s.page

	// this is probably quite slow :(
	page_width := page.width * t.channels
	slot_end := s.u * t.channels

	slot_width := (s.u-s.x)*t.channels

	for j := 0; j < s.v-s.y; j++ {
		// byte pos of our y axis
		vert := (s.y + j) * page_width
		// byte pos of our x axis
		horiz := s.x * t.channels
		// and copy!
		copy(s.page.data[vert+horiz..vert+slot_end], data[j*data_width..(j+1)*data_height])
	}
}

fn (mut t TextureAtlas) flush() {
	for p in t.pages {
		if !p.dirty { continue }

		// update the texture in sokol
		mut image_content := C.sg_image_content{}
		image_content.subimage[0][0] = C.sg_subimage_content {
			ptr: p.data.data
			size: p.data.len
		}

		// send to gpu
		C.sg_update_image(p.texture, &image_content)
	}
}
