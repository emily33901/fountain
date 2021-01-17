module util

import sokol.sgl

// TODO at some point we are going to need to lock texture slots

pub struct Slot {
pub:
	// what page this slot is on
	page &Page

	// logical x, y, u, v
	x int
	y int
	// x + width
	u int
	// y + height
	v int

	// texture x, y, u, v
	tx f32
	ty f32
	// x + width
	tu f32
	// y + height
	tv f32
}

pub fn new_slot(page &Page, x int, y int, u int, v int, tex_width int, tex_height int) Slot {
	return Slot{
		page: page
		x: x
		y: y
		u: u
		v: v

		tx: (f32(x) / tex_width)
		ty: (f32(y) / tex_height)
		tu: (f32(u) / tex_width)
		tv: (f32(v) / tex_height)
	}
}

struct TextureAtlas {
pub mut:
	pages []Page
}

fn new_texture_atlas(width int, height int, slots int) TextureAtlas {
	mut pages := []Page{len: slots}

	for i := 0; i < slots; i++ {
		tex_desc := C.sg_image_desc {
			width: width
			height: height
			num_mipmaps: 0
			min_filter:   .linear
			mag_filter:   .linear
			usage: .dynamic
			wrap_u: .clamp_to_edge
			wrap_v: .clamp_to_edge
			label: &byte(0)
			d3d11_texture: 0
		}

		pages[i] = Page{
			texture: C.sg_make_image(&tex_desc)
			data: []byte{len: (width * height * 4), init: 0}

			width: width
			height: height
		} 
	}
	
	mut atlas := TextureAtlas {
		pages: pages
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
fn (mut t TextureAtlas) update(s Slot, data []byte) {
	if data.len > ((s.u-s.x) * (s.v-s.y) * 4) {
		panic('Data is too big for slot')
	}

	page := s.page

	// this is probably quite slow :(
	page_width := page.width * 4
	slot_end := s.u * 4

	slot_width := (s.u-s.x)*4

	for j := 0; j < s.v-s.y; j++ {
		// byte pos of our y axis
		vert := (s.y + j) * page_width
		// byte pos of our x axis
		horiz := s.x * 4
		// and copy!
		copy(s.page.data[vert+horiz..vert+slot_end], data[j*slot_width..(j+1)*slot_width])
	}
}

fn (mut t TextureAtlas) flush() {
	for p in t.pages {
		if !p.dirty {
			continue
		}

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
