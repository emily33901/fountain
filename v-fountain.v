module main

import ui

fn create_dc() DrawContext {
	return DrawContext(C.CreateCompatibleDC(C.NULL))
}

fn C.AllocConsole()

fn C.GetConsoleWindow() voidptr

fn main() {
	dc := create_dc()
	assert dc != C.NULL
	font := new_font(height: 20, face_name: 'Tahoma') or { panic('failed to create font') }
	window := ui.window({
		width: 1280
		height: 720
		title: 'test window'
	}, [])
	ui.run(window)
}
