module main

// node in the list
struct MetricsNode {
pub:
	key   rune
	value Metrics
pub mut:
	next  &MetricsNode = voidptr(0)
	prev  &MetricsNode = voidptr(0)
}

struct MetricsList {
pub mut:
	front &MetricsNode = voidptr(0)
	back &MetricsNode = voidptr(0)
}

fn new_metrics_list() MetricsList {
	return MetricsList {
	}
}

fn (mut l MetricsList) remove(mut node MetricsNode) &MetricsNode {
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

fn (mut l MetricsList) add_front(mut node MetricsNode) {
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

fn (mut l MetricsList) promote(mut node MetricsNode) {
	l.remove(mut node)
	l.add_front(mut node)
}

fn (mut l MetricsList) kill_back() {
	node := l.remove(mut l.back)
	unsafe { free(node) }
}

fn (mut l MetricsList) new_node(key rune, value Metrics) &MetricsNode {
	mut n := &MetricsNode{
		key: key
		value: value
	}
	l.add_front(mut n)

	return n
}

// lru cache implementation
struct MetricsCache {
mut:
	// max length of the cache
	max_len int
	// the hash of nodes
	cache   map[rune]&MetricsNode

	list MetricsList
}

fn new_metrics_cache(max_len int) MetricsCache {
	return MetricsCache{
		max_len: max_len
		list: new_metrics_list()
	}
}

fn (mut c MetricsCache) add(key rune, value Metrics) {
	if key in c.cache {
		// key is already in here
		// so promote it to the front of the list
		mut node := c.cache[key]
		c.list.promote(mut node)
	} else {
		// key is not already in here
		// so kill the last item (if we're too long) and put this value 
		// at the front
		if c.cache.len > c.max_len {
			k := c.list.back.key
			c.list.kill_back()
			c.cache.delete_1(k)
		}
		// add the new value to the front
		node := c.list.new_node(key, value)
		c.cache[key] = node
	}
}

fn (mut c MetricsCache) get(key rune) ?Metrics {
	if key in c.cache {
		mut node := c.cache[key]
		c.list.promote(mut node)
		return node.value
	}
	return none
}
