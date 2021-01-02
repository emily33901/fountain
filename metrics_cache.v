module main

// node in the list
struct LruListNode {
pub:
	key   rune
	value Metrics
pub mut:
	next  &LruListNode
	prev  &LruListNode
}

fn promote(mut node LruListNode, mut front LruListNode) &LruListNode {
	// remove ourselves from the list by tying
	// our next to our prev and vice versa
	mut next := node.next
	mut prev := node.prev
	// link prev to next if either of them exist
	if next != voidptr(0) {
		next.prev = prev
	}
	if prev != voidptr(0) {
		prev.next = next
	}
	// put ourselves at the front
	// and set oruselves as prev on it
	node.next = front
	if front != voidptr(0) {
		front.prev = node
	}
	return node
}

fn kill(mut node LruListNode) &LruListNode {
	if node.prev != voidptr(0) {
		node.prev.next = voidptr(0)
	}
	prev := node.prev
	unsafe { free(node) }
	return prev
}

fn new_node(key rune, value Metrics) &LruListNode {
	return &LruListNode{
		key: key
		value: value
		prev: voidptr(0)
		next: voidptr(0)
	}
}

// lru cache implementation
struct MetricsCache {
mut:
	// max length of the cache
	max_len int
	// the hash of nodes
	cache    map[rune]&LruListNode
	// the list references
	front   &LruListNode
	back    &LruListNode
}

fn new_lru_cache(max_len int) MetricsCache {
	return MetricsCache{
		max_len: max_len
		front: voidptr(0)
		back: voidptr(0)
	}
}

fn (mut c MetricsCache) add(key rune, value Metrics) {
	if key in c.cache {
		// key is already in here
		// so promote it to the front of the list
		mut node := c.cache[key]
		c.front = promote(mut node, mut c.front)
	} else {
		// key is not already in here
		// so kill the last item (if we're too long) and put this value 
		// at the front
		if c.cache.len > c.max_len {
			k := c.back.key
			c.back = kill(mut c.back)
			c.cache.delete_1(k)
		}
		// add the new value to the front
		mut node := new_node(key, value)
		c.front = promote(mut node, mut c.front)

		c.cache[key] = node
		if c.cache.len == 1 {
			c.back = node
		}
	}
}

fn (mut c MetricsCache) get(key rune) ?Metrics {
	if key in c.cache {
		mut node := c.cache[key]
		c.front = promote(mut node, mut c.front)
		return node.value
	}
	return none
}
