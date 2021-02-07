module util

import sokol.sgl
import sokol.gfx

struct Page {
pub:
	texture C.sg_image

	width int
	height int

	slot_width int
	slot_height int

mut:
	data []byte

	curx int
	cury int

pub mut:
	list TextureSlotList
	dirty bool
}

fn new_page(width int, height int, slot_width int, slot_height int, channels int, pixel_format gfx.PixelFormat) Page {
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

	return Page{
		texture: C.sg_make_image(&tex_desc)
		// add some extra space so we dont go over
		data: []byte{len: ((width * height) * channels), init: 0}

		width: width
		height: height
		
		slot_width: slot_width
		slot_height: slot_height

		list: new_texture_slot_list()
	} 
}

fn (mut t Page) slot(key rune, width int, height int) (&TextureSlotNode, rune) {
	// check we have enough horizontal space
	if t.curx + t.slot_width > t.width {
		// Not enough space on this line see if we will fit on the next
		t.cury += t.slot_height
		t.curx = 0
	}

	// we returned a new slot so we will need to be flushed this frame
	t.dirty = true

	if t.cury + t.slot_height > t.height {
		// Not enough space left on this texture
		// so we need to replace the last used glyph

		v := t.list.back.value
		k := t.list.back.key
		t.list.kill_back()

		node := t.list.new_node(key, v)

		return node, k
	}

	x := t.curx
	y := t.cury

	t.curx += t.slot_width

	node := t.list.new_node(key, new_slot(
		t,
		x,
		y,
		x + t.slot_width,
		y + t.slot_height,
		t.width,
		t.height
	))

	return node, rune(-1)
}

