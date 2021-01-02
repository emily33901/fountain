module main

import os

fn C.DeleteObject()

fn C.CreateDIBSection() Handle

struct Bitmap {
	context DrawContext
	handle  Handle
pub:
	data    []byte
}

struct BitmapConfig {
	context     DrawContext
	width       int
	height      int
	planes      int = 1
	bits        int = 32
	compression int = bi_rgb
}

struct C.BITMAPINFO {
}

fn new_bitmap(config BitmapConfig) ?Bitmap {
	header := C.BITMAPINFOHEADER{
		biSize: sizeof(C.BITMAPINFOHEADER)
		biWidth: config.width
		biHeight: -config.height
		biPlanes: i16(config.planes)
		biBitCount: i16(config.bits)
		biCompression: config.compression
	}
	temp := voidptr(0)
	handle := C.CreateDIBSection(config.context, &C.BITMAPINFO(&header), dib_rgb_colors,
		&temp, C.NULL, 0)
	// println('${os.get_error_msg(int(C.GetLastError()))}')
	if handle == 0 {
		return none
	}
	//len := ((config.width * config.bits + 31) / 32) * 4 * config.height
	len := config.width * config.height * 4
	
	return Bitmap{
		context: config.context
		handle: handle
		data: array{
			data: temp
			len: len
			cap: len
			element_size: 1
		}
	}
}

fn (b Bitmap) free() {
	C.DeleteObject(b.handle)
}

fn (b Bitmap) @select() {
	C.SelectObject(b.context, b.handle)
}
