module util

import sokol.sgl

struct Slot {
pub:
	x int
	y int
	// x + width
	u int
	// y + height
	v int
}

struct TextureAtlas {
pub:
	texture C.sg_image
	width int
	height int

pub mut:
	// data so we can go update and give to sokol
	data []byte

	// where the next slot should go
	curx int
	cury int

	// how large the current line is
	ascent int
}

fn new_texture_atlas(width int, height int) TextureAtlas {
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

	tex := C.sg_make_image(&tex_desc)
	
	return TextureAtlas {
		texture: tex
		width: width
		height: height
		data: []byte{len: (width * height * 4), init: 0}
	}
}

fn (mut t TextureAtlas) free() {
	C.sg_destroy_image(t.texture)
}

fn (mut t TextureAtlas) slot(width int, height int) ?Slot {
	// check we have enough horizontal space
	if t.curx + width > t.width {
		// Not enough space on this line see if we will fit on the next
		t.cury += t.ascent
		t.curx = 0
		t.ascent = 0
	}

	if t.cury + height > t.height {
		// Not enough space left on this texture
		return none
	}

	if height > t.ascent {
		// we are now the tallest glyph so
		// up the size please
		t.ascent = height
	}

	x := t.curx
	y := t.cury

	t.curx += width

	return Slot {
		x
		y
		x + width
		y + height
	}
}

fn (mut t TextureAtlas) update(s Slot, data []byte) {
	if data.len > ((s.u-s.x) * (s.v-s.y) * 4) {
		panic('Data is too big for slot')
	}

	// this is probably quite slow :(
	atlas_width := t.width * 4
	slot_end := s.u * 4

	slot_width := (s.u-s.x)*4

	for j := 0; j < s.v-s.y; j++ {
		// byte pos of our y axis
		vert := (s.y + j) * atlas_width
		// byte pos of our x axis
		horiz := s.x * 4
		// and copy!
		copy(t.data[vert+horiz..vert+slot_end], data[j*slot_width..(j+1)*slot_width])
	}
}

fn (mut t TextureAtlas) flush() {
	// update the texture in sokol
	mut image_content := C.sg_image_content{}
	image_content.subimage[0][0] = C.sg_subimage_content {
		ptr: t.data.data
		size: t.data.len
	}

	// send to gpu
	C.sg_update_image(t.texture, &image_content)
}
