module util

import sokol.sgl

struct Page {
pub:
	texture C.sg_image

	width int
	height int

mut:
	data []byte

	curx int
	cury int
	ascent int

pub mut:
	dirty bool
}

fn (mut t Page) slot(width int, height int) ?Slot {
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

	// we returned a new slot so we will need to be flushed next frame
	t.dirty = true

	return new_slot(
		t,
		x,
		y,
		x + width,
		y + height,
		t.width,
		t.height
	)
}

