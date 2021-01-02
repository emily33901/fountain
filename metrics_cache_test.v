module main

fn test_lru_cache() {
	// add some numbers to the cache
	mut cache := new_metrics_cache(100)
	for i := 0; i < 10000; i++ {
		cache.add(i, Metrics{i, i, i})
	}
	println('test!')
	x := cache.get(9999) or {
		assert false
		panic('appease compiler')
	}
	println('$x')
	for i := 10000 - 1; i > 9800; i-- {
		_ := cache.get(i) or {
			assert i < 9900
			continue
		}
	}
}
