module util

struct TextureCache {
mut:
	// the hash of nodes
	cache   map[rune]&TextureSlotNode

	misses  int

pub mut:
	atlas TextureAtlas
}

pub fn new_texture_cache(max_char_width int, max_char_height int, channels int) TextureCache {
	return TextureCache{
		atlas: new_texture_atlas(max_char_width, max_char_height, channels)
	}
}

pub fn (mut c TextureCache) add(key rune, width int, height int, glyph_width int, glyph []byte) Slot {
	if key in c.cache {
		// key is already in here
		// so promote it to the front of the list
		mut node := c.cache[key]
		node.value.page.list.promote(mut node)

		return node.value
	}

	c.misses++

	node, removed := c.atlas.slot(key, width, height)

	if removed != rune(-1) {
		c.cache.delete_1(removed)
	}
	
	c.atlas.update(node.value, glyph_width, height, glyph)

	// add the new value to our cache
	c.cache[key] = node

	return node.value
}

pub fn (mut c TextureCache) get(key rune) ?Slot {
	if key in c.cache {
		mut node := c.cache[key]
		return node.value
	}
	return none
}

pub fn (mut c TextureCache) flush() {
	c.atlas.flush()
}

pub fn (mut c TextureCache) cache_misses() int {
	m := c.misses
	c.misses = 0

	return m
}
