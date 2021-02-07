module util

import sokol.sgl
import sokol.gfx

// Texture atlas has 4 pages
// one small atlas based around
// one tall atlas based around
// one wide atlas based around
// and one atlas that can fit any size character

struct TextureAtlas {
pub mut:
	pages [4]Page
	channels int
}

fn new_texture_atlas(max_slot_width int, max_slot_height int, channels int) TextureAtlas {
	pixel_format := if channels == 4 {
		gfx.PixelFormat.rgba8
	} else if channels == 1 {
		gfx.PixelFormat.r8
	} else {
		panic('Dont know what to do with $channels channels')
		gfx.PixelFormat.@none
	}

	mut atlas := TextureAtlas {
		pages: [
			new_page(1024, 1024, max_slot_width / 2, max_slot_height / 2, channels, pixel_format),
			new_page(1024, 2096, max_slot_width / 2, max_slot_height, channels, pixel_format),
			new_page(2096, 1024, max_slot_width, max_slot_height / 2, channels, pixel_format),
			new_page(2096, 2096, max_slot_width, max_slot_height, channels, pixel_format),
		]!
		channels: channels
	}

	return atlas
}

fn (mut t TextureAtlas) free() {
	for p in t.pages {
		C.sg_destroy_image(p.texture)
	}
}

fn (mut t TextureAtlas) slot(key rune, width int, height int) (&TextureSlotNode, rune) {
	// find the appropriate page for this size character
	mut page := t.find_page(width, height)

	// now get a slot from it
	node, removed := page.slot(key, width, height)

	return node, removed
}

fn (mut t TextureAtlas) find_page(width int, height int) &Page {
	for i, _ in t.pages {
		p := &t.pages[i]
		if width <= p.slot_width && height <= p.slot_height {
			return p
		}
	}

	panic('Unable to find page (this shoud be impossible')
}

[direct_array_access]
fn (mut t TextureAtlas) update(s Slot, data_width int, data_height int, data []byte) {
	// if data.len > ((s.u-s.x) * (s.v-s.y) * t.channels) {
	// 	// add another page that is the right size
	// 	println('invalid size so youre going to get garbage')
	// }

	page := s.page

	// this is probably quite slow :(
	page_width := page.width * t.channels
	slot_end := s.u * t.channels

	slot_width := (s.u-s.x)*t.channels

	for j := 0; j < data_height; j++ {
		// byte pos of our y axis
		vert := (s.y + j) * page_width
		// byte pos of our x axis
		horiz := s.x * t.channels
		// and copy!
		copy(page.data[vert+horiz..vert+slot_end], data[j*(data_width * t.channels)..(j+1)*(data_width * t.channels)])
	}
}

fn (mut t TextureAtlas) flush() {
	for mut p in t.pages {
		if !p.dirty { continue }

		p.dirty = false

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
