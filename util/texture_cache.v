module util

// node in the list
struct TextureSlotNode {
pub:
	key   rune
	value Slot
pub mut:
	next  &TextureSlotNode = voidptr(0)
	prev  &TextureSlotNode = voidptr(0)
}

struct TextureSlotList {
pub mut:
	front &TextureSlotNode = voidptr(0)
	back &TextureSlotNode = voidptr(0)
}

fn new_texture_slot_list() TextureSlotList {
	return TextureSlotList {
	}
}

fn (mut l TextureSlotList) remove(mut node TextureSlotNode) &TextureSlotNode {
	mut next := node.next
	mut prev := node.prev

	// link prev to next if either of them exist
	if next != voidptr(0) {
		next.prev = prev
	}

	if prev != voidptr(0) {
		prev.next = next
	}

	// update back if this node is the back
	if voidptr(node) == voidptr(l.back) {
		l.back = prev
	}

	// update front if this node is the front
	if voidptr(node) == voidptr(l.front) {
		l.front = next
	}
	
	// remove any links that we might have
	node.prev = voidptr(0)
	node.next = voidptr(0)

	return node
}

fn (mut l TextureSlotList) add_front(mut node TextureSlotNode) {
	if l.front != voidptr(0) {
		l.front.prev = node
	}
	node.next = l.front
	l.front = node

	// TODO hack
	if l.back == voidptr(0) {
		l.back = l.front
	}
}

fn (mut l TextureSlotList) promote(mut node TextureSlotNode) {
	l.remove(mut node)
	l.add_front(mut node)
}

fn (mut l TextureSlotList) kill_back() {
	node := l.remove(mut l.back)
	unsafe { free(node) }
}

fn (mut l TextureSlotList) new_node(key rune, value Slot) &TextureSlotNode {
	mut n := &TextureSlotNode{
		key: key
		value: value
	}
	l.add_front(mut n)

	return n
}

struct TextureCache {
mut:
	// the hash of nodes
	cache   map[rune]&TextureSlotNode
	list    TextureSlotList

pub mut:
	atlas TextureAtlas
}

pub fn new_texture_cache(width int, height int) TextureCache {
	return TextureCache{
		atlas: new_texture_atlas(width, height)
		list: new_texture_slot_list()
	}
}

pub fn (mut c TextureCache) add(key rune, width int, height int, glyph []byte) Slot {
	if key in c.cache {
		// key is already in here
		// so promote it to the front of the list
		mut node := c.cache[key]
		c.list.promote(mut node)

		return node.value
	}
	
	// try and get a slot
	slot := c.atlas.slot(width, height) or {
		// no space left in the atlas so reuse the
		// last slot
		v := c.list.back.value
		k := c.list.back.key
		c.list.kill_back()
		c.cache.delete_1(k)

		v
	}

	c.atlas.update(slot, glyph)

	// add the new value to the front
	node := c.list.new_node(key, slot)
	c.cache[key] = node

	return slot
}

pub fn (mut c TextureCache) get(key rune) ?Slot {
	if key in c.cache {
		mut node := c.cache[key]
		c.list.promote(mut node)
		return node.value
	}
	return none
}

pub fn (mut c TextureCache) flush() {
	c.atlas.flush()
}
