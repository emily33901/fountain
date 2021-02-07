module util

pub struct Slot {
pub mut:
	// what page this slot is on
	page Page

pub:
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
