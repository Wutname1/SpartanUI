local fn = require("functional");

(function()
	local dump, dump_table, test

	dump_table = function(t)
		local t = fn.map(t, function(x) return type(x) == "table" and dump(x) or tostring(x) end)
		return "{ " .. table.concat(t, ", ") .. " }"
	end

	dump = function(v)
		if type(v) == "table" then
			return dump_table(v)
		else
			return tostring(v)
		end
	end

	test = function(t1, t2)
		local eq
		if type(t1) == "table" then
			eq = type(t2) == "table" and fn.equal(t1, t2, true)
		else
			eq = t1 == t2
		end

		if not eq then
			print("test failed:")
			print("\texpected: " .. dump(t1))
			print("\tgot: " .. dump(t2))
			return false
		end
		return true
	end

	-- test data
	local lst = { 1, 3, 2, 5, 4 }
	local tbl = { ["a"] = 1, ["b"] = 2, ["c"] = 3, ["d"] = 4, ["e"] = 5 }
	local function f(a1, a2, a3, a4, a5) return a1, a2, a3, a4, a5 end

	-- all
	assert(test(true, fn.all({}, function(v) return v > 0 end)))
	assert(test(true, fn.all(lst, function(v) return v > 0 end)))
	assert(test(false, fn.all(lst, function(v) return v > 1 end)))
	assert(test(fn.every, fn.all))

	-- any
	assert(test(false, fn.any({}, function(v) return v > 0 end)))
	assert(test(true, fn.any(lst, function(v) return v > 3 end)))
	assert(test(false, fn.any(lst, function(v) return v > 10 end)))
	assert(test(fn.some, fn.any))

	-- binary_search
	assert(test({}, { fn.binary_search({}, 1) }))
	assert(test({ 1, 1 }, { fn.binary_search(fn.sort(lst), 1) } ))
	assert(test({ 2, 2 }, { fn.binary_search(fn.sort(lst), 2) } ))
	assert(test({ 3, 3 }, { fn.binary_search(fn.sort(lst), 3) } ))
	assert(test({ 4, 4 }, { fn.binary_search(fn.sort(lst), 4) } ))
	assert(test({ 5, 5 }, { fn.binary_search(fn.sort(lst), 5) } ))
	assert(test({}, { fn.binary_search(fn.sort(lst), 6) }))

	-- bind
	assert(test({ 1, 2 }, { fn.bind(f, 1)(2) }))
	assert(test({ 1, 2, 3, 4 }, { fn.bind(f, 1, 2)(3, 4) }))

	-- bind_nth
	assert(test({ 1, 2 }, { fn.bind_nth(f, 1, 1)(2) }))
	assert(test({ 1, 2, 3 }, { fn.bind_nth(f, 2, 2)(1, 3) }))
	assert(test({ 1, 2, 3, 4 }, { fn.bind_nth(f, 1, 1, 2)(3, 4) }))
	assert(test({ 1, 2, 3, 4, 5 }, { fn.bind_nth(f, 2, 2, 3)(1, 4, 5) }))

	-- clone
	assert(test({}, fn.clone({})))
	assert(test(lst, fn.clone(lst)))
	assert(test(tbl, fn.clone(tbl)))
	do
		local t = { 1, tbl }
		local st = fn.clone(t)
		local dt = fn.clone(t, true)
		assert(test(t, st))
		assert(test(t, dt))
		assert(st[2] == tbl)
		assert(dt[2] ~= tbl)
	end

	-- concat
	assert(test({}, fn.concat()))
	assert(test({}, fn.concat({}, {})))
	assert(test({ 1 }, fn.concat({ 1 })))
	assert(test({ 1, 2 }, fn.concat({ 1 }, { 2 })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.concat({ 1, 2, 3, 4, 5 })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.concat({ 1, 2 }, { 3, 4, 5 })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.concat({ 1, 2 }, { 3, 4 } , { 5 })))

	-- contains
	assert(test(false, fn.contains({}, 5)))
	assert(test(true, fn.contains(lst, 5)))
	assert(test(false, fn.contains(lst, 6)))
	assert(test(fn.elem, fn.contains))

	-- difference
	assert(test({}, fn.difference({})))
	assert(test({ 1, 2, 3 }, fn.difference({ 1, 2, 3, 4, 5 }, { 4, 5 })))
	assert(test({ 1, 2 }, fn.difference({ 1, 2, 3, 4, 5 }, { 3 }, { 4, 5 })))
	assert(test({ 1 }, fn.difference({ 1, 2, 3, 4, 5 }, { 2, 3 }, { 4, 5, 6 }, { 2, 3, 4, 6 })))
	assert(test({ }, fn.difference({ 1, 2, 3, 4, 5 }, { 1, 2, 3 }, { 4, 5, 6 })))
	assert(test({ "a", "bc" }, fn.difference(function(s) return #s end, { "a", "bc", "def" }, { "123" })))

	-- each
	do
		local n = 0
		assert(test(lst, fn.each(lst, function(v) n = n + v end)))
		assert(test(n, fn.sum(lst)))
	end
	assert(test(fn.for_each, fn.each))

	-- equal
	assert(test(false, fn.equal({ 1, 2 }, { 1, 5, 7 })))
	assert(test(true, fn.equal({ 1, 2, 3 }, { 1, 2, 3 })))
	assert(test(false, fn.equal({ 1, 2, { 3 } }, { 1, 2, { 3 } })))
	assert(test(true, fn.equal({ 1, 2, { 3 } }, { 1, 2, { 3 } }, true)))
	assert(test(true, fn.equal({ ["a"] = 1, ["b"] = 2, ["c"] = 3 }, { ["a"] = 1, ["b"] = 2, ["c"] = 3 })))
	assert(test(false, fn.equal({ ["a"] = 1, ["b"] = 2, ["c"] = 3 }, { ["a"] = 2, ["b"] = 2, ["c"] = 3 })))
	assert(test(false, fn.equal({ ["a"] = 1, ["b"] = 2, ["c"] = 3 }, { ["a"] = 1, ["b"] = 2, ["c"] = 3, ["d"] = 4 })))
	assert(test(false, fn.equal({ ["a"] = 1, ["b"] = 2, ["c"] = 3 }, { ["a"] = 1, ["b"] = 2 })))
	do
		local t = { 1, tbl }
		local st = fn.clone(t)
		local dt = fn.clone(t, true)
		assert(test(true, fn.equal(t, st))) -- shallow test
		assert(test(false, fn.equal(t, dt)))
		assert(test(true, fn.equal(t, st, true))) -- deep test
		assert(test(true, fn.equal(t, dt, true)))
	end

	-- filter
	assert(test({}, fn.filter({}, function(v) return v > 1 end)))
	assert(test({ 3, 2, 5, 4 }, fn.filter(lst, function(v) return v > 1 end)))

	-- find_first_of
	assert(test({}, { fn.find_first_of({}) }))
	assert(test({ 3, 2 }, { fn.find_first_of(lst, 3) }))
	assert(test({ 3, 2 }, { fn.find_first_of(lst, 6, 3) }))
	assert(test({ 1, 1 }, { fn.find_first_of(lst, 5, 1) }))
	assert(test({ 4, 5 }, { fn.find_first_of(lst, 6, 7, 4) }))

	-- find_if
	assert(test({}, { fn.find_if({}, function(v) return v == 5 end) }))
	assert(test({ 5, 4 }, { fn.find_if(lst, function(v) return v == 5 end) }))
	assert(test({}, { fn.find_if(lst, function(v) return v == 6 end) }))

	-- find_last_of
	assert(test({}, { fn.find_last_of({}) }))
	assert(test({ 3, 2 }, { fn.find_last_of(lst, 3) }))
	assert(test({ 3, 2 }, { fn.find_last_of(lst, 6, 3) }))
	assert(test({ 5, 4 }, { fn.find_last_of(lst, 5, 1) }))
	assert(test({ 4, 5 }, { fn.find_last_of(lst, 5, 1, 4) }))

	-- flatten
	assert(test({}, fn.flatten({})))
	assert(test({ 1, 2 }, fn.flatten({ 1, 2 })))
	assert(test({ 1, 2, 3 }, fn.flatten({ 1, 2, { 3 } })))
	assert(test({ 1, 2, { 3 } }, fn.flatten({ 1, 2, { { 3 } } }, true)))
	assert(test({ 1, 2, 3, { 4 } }, fn.flatten({ 1, 2, { 3 }, { { 4 } } }, true)))
	assert(test({ 1, 2, 3, 4, 5 }, fn.flatten({ 1, 2, { { 3 } }, { 4, 5 } })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.flatten({ 1, 2, { { 3 } }, { { { 4 } }, 5 } })))

	-- from_iterator
	assert(test({}, fn.from_iterator(pairs({}))))
	assert(test({ { 1, 1 }, { 2, 2 } }, fn.from_iterator(ipairs({ 1, 2 }))))
	assert(test(lst, fn.from_iterator(function(i, v) return v end, ipairs(lst))))
	assert(test(fn.values(tbl), fn.from_iterator(function(k, v) return v end, pairs(tbl))))
	assert(test(fn.keys(tbl), fn.from_iterator(function(k, v) return k end, pairs(tbl))))

	-- invert
	assert(test({}, fn.invert({})))
	assert(test({ ["v"] = "k" }, fn.invert({ ["k"] = "v" })))
	assert(test({ "a", "b", "c", "d", "e" }, fn.invert(tbl)))

	-- intersection
	assert(test({}, fn.intersection({})))
	assert(test({ 4, 4, 5 }, fn.intersection({ 1, 4, 2, 3, 4, 5 }, { 4, 5 })))
	assert(test({ 4, 5 }, fn.intersection({ 1, 2, 3, 4, 5 }, { 4, 5 })))
	assert(test({ 5 }, fn.intersection({ 1, 2, 3, 4, 5 }, { 3, 5 }, { 4, 5 })))
	assert(test({ 1 }, fn.intersection({ 1, 2, 3, 4, 5 }, { 1, 2, 3 }, { 4, 5, 1, 6 }, { 2, 1, 3, 4, 6 })))
	assert(test({ }, fn.intersection({ 1, 2, 3, 4, 5 }, { 1, 2, 3 }, { 4, 5, 1, 6 }, { 2, 3, 4, 6 })))
	assert(test({ }, fn.intersection({ 1, 2, 3, 4, 5 }, { 1, 2, 3 }, { 4, 5, 6 })))
	assert(test({ "def" }, fn.intersection(function(s) return #s end, { "a", "bc", "def" }, { "123" })))

	-- keys
	assert(test({}, fn.keys({})))
	assert(test({ "a", "b", "c", "d", "e" }, fn.sort(fn.keys(tbl))))

	-- map
	assert(test({}, fn.map({})))
	assert(test({ 2, 6, 4, 10, 8 }, fn.map(lst, function(v) return v * 2 end)))

	-- max
	assert(test(nil, fn.max({})))
	assert(test(5, fn.max(lst)))

	-- merge
	assert(test({}, fn.merge()))
	assert(test({ 2, 3 }, fn.merge({ 1 }, {}, { 2, 3 })))
	assert(test({ 2, 3 }, fn.merge({ 1 }, {}, { 1, 3 }, { 2 })))
	assert(test({ ["a"] = 1, ["b"] = 2 }, fn.merge({ ["a"] = 1 }, { ["b"] = 2 })))
	assert(test({ ["a"] = 1, ["b"] = 3, ["c"] = 4 }, fn.merge({ ["a"] = 1, ["b"] = 2 }, { ["b"] = 5 }, { ["b"] = 3, ["c"] = 4 })))

	-- min
	assert(test(nil, fn.min({})))
	assert(test(2, fn.min({ 2 })))
	assert(test(1, fn.min(lst)))

	-- pairs
	assert(test({}, fn.pairs({})))
	assert(test({ { "a", 1 }, { "b", 2 } }, fn.pairs({ ["a"] = 1, ["b"] = 2 })))
	assert(test(fn.zip(fn.keys(tbl), fn.values(tbl)), fn.pairs(tbl)))

	-- range
	assert(test({}, fn.range(0)))
	assert(test({ 1 }, fn.range(1)))
	assert(test({ 1, 2, 3 }, fn.range(3)))
	assert(test({ 2, 3 }, fn.range(2, 3)))
	assert(test({ 0, 2, 4 }, fn.range(0, 4, 2)))
	assert(test({ -1, -2 }, fn.range(-1, -2, -1)))

	-- reduce
	assert(test(nil, fn.reduce({}, function(r, v) return r + v end)))
	assert(test(5, fn.reduce({ 5 }, function(r, v) return r + v end)))
	assert(test(15, fn.reduce(lst, function(r, v) return r + v end)))
	assert(test(16, fn.reduce(lst, function(r, v) return r + v end, 1)))
	assert(test(15, fn.reduce({ 5 }, function(r, v) return r + v end, 10)))
	assert(test(1, fn.reduce({ 8, 4, 2, 1 }, function(r, v) return r / v end)))
	assert(test(fn.foldl, fn.reduce))

	-- reduce_right
	assert(test(nil, fn.reduce_right({}, function(r, v) return r + v end)))
	assert(test(5, fn.reduce_right({ 5 }, function(r, v) return r + v end)))
	assert(test(1, fn.reduce_right({ 1, 2, 4, 8 }, function(r, v) return r / v end)))
	assert(test(fn.foldr, fn.reduce_right))

	-- reverse
	assert(test({}, fn.reverse({})))
	assert(test({ 4, 5, 2, 3, 1 }, fn.reverse(lst)))

	-- shuffle
	assert(test(3, #fn.shuffle({ 1, 2, 3 })))

	-- shuffle_inplace
	assert(test(3, #fn.shuffle_inplace({ 1, 2, 3 })))
	do
		local l = fn.clone(lst)
		assert(test(l, fn.shuffle_inplace(l)))
	end

	-- slice
	assert(test({ }, fn.slice({}, 0)))
	assert(test({ 1, 3, 2, 5, 4 }, fn.slice(lst)))
	assert(test({ 1, 3, 2, 5, 4 }, fn.slice(lst, 1)))
	assert(test({ 3, 2, 5 }, fn.slice(lst, 2, 4)))
	assert(test({ 5, 4 }, fn.slice(lst, -2)))
	assert(test({ 3, 2, 5 }, fn.slice(lst, 2, -1)))
	assert(test({ 1, 3, 2 }, fn.slice(lst, 1, -2)))

	-- sort
	assert(test({}, fn.sort({})))
	assert(test({ 1, 2, 3, 4, 5 }, fn.sort(lst)))
	assert(test({ 1, 3, 2, 5, 4 }, lst))

	-- sort_inplace
	assert(test({}, fn.sort_inplace({})))
	assert(test({ 1, 2, 3, 4, 5 }, fn.sort_inplace(fn.clone(lst))))
	do
		local l = fn.clone(lst)
		assert(test(l, fn.sort_inplace(l)))
	end

	-- sorted_index
	assert(test(1, fn.sorted_index({}, 4)))
	assert(test(4, fn.sorted_index({ 1, 2, 3, 4, 5, 6 }, 4)))

	-- sorted_insert
	assert(test({ 4 }, fn.sorted_insert({}, 4)))
	assert(test({ 1, 2, 3, 4, 5}, fn.sorted_insert({ 1, 2, 3, 5 }, 4)))

	-- size
	assert(test(0, fn.size({})))
	assert(test(2, fn.size({ 1, 2 })))
	assert(test(3, fn.size({ 1, 2, 3 })))
	assert(test(3, fn.size({ 1, 2, { 3 } })))
	assert(test(3, fn.size({ ["a"] = 1, ["b"] = 2, ["c"] = 3 })))
	assert(test(4, fn.size({ ["a"] = 1, ["b"] = 2, ["c"] = 3, ["d"] = 4 })))

	-- sum
	assert(test(nil, fn.sum({})))
	assert(test(15, fn.sum(lst)))

	-- union
	assert(test({}, fn.union()))
	assert(test({}, fn.union({}, {})))
	assert(test({ 1, 2, 3, 4, 5 }, fn.union({ 1, 2, 3, 3, 4, 5 })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.union({ 1, 2 }, { 1, 3, 4, 5 })))
	assert(test({ 1, 2, 3, 4, 5 }, fn.union({ 1, 2 }, { 1, 2, 3, 4 } , { 3, 5 })))

	-- uniq
	assert(test({}, fn.uniq({})))
	assert(test({ 2, 3, 1 }, fn.uniq({ 2, 3, 2, 1, 1 })))
	assert(test({ 1, 2, 3 }, fn.uniq({ 1, 1, 2, 2, 3 }, true)))
	assert(test({ 1, 2 }, fn.uniq({ 1, 1, 2, 2, 3 }, true, function(v) return math.floor(v/2) end)))
	
	-- unzip
	assert(test({}, { fn.unzip({}) }))
	assert(test({ { 1, 2 } }, { fn.unzip({ { 1 }, { 2 } }) }))
	assert(test({ { 1, 2 }, { 3, 4 } }, { fn.unzip({ { 1, 3 }, { 2, 4 } }) }))
	assert(test({ { 1, 2 }, { 3, 4 }, { 5, 6 } }, { fn.unzip({ { 1, 3, 5 }, { 2, 4, 6 } }) }))
	assert(test({ { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 } }, { fn.unzip({ { 1, 4, 7 }, { 2, 5, 8 }, { 3, 6, 9 } }) }))

	-- values
	assert(test({ 1, 2, 3, 4, 5 }, fn.sort(fn.values(tbl))))

	-- zip
	assert(test({}, fn.zip({})))
	assert(test({ { 1 }, { 2 } }, fn.zip({ 1, 2 })))
	assert(test({ { 1, 3 }, { 2, 4 } }, fn.zip({ 1, 2 }, { 3, 4 })))
	assert(test({ { 1, 3, 5 }, { 2, 4, 6 } }, fn.zip({ 1, 2 }, { 3, 4 }, { 5, 6 })))
	assert(test({ { 1, 4, 7 }, { 2, 5, 8 }, { 3, 6, 9 } }, fn.zip({ 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 })))
	assert(test({ { 1, 3, 5 }, { 2, 4, 6 } }, fn.zip({ 1, 2, 10 }, { 3, 4 }, { 5, 6 })))
	assert(test({ { 1, 3, 5 }, { 2, 4, 6 } }, fn.zip({ 1, 2, 10 }, { 3, 4 }, { 5, 6, 20, 30 })))

	-- zip_with
	assert(test({}, fn.zip_with(function(a, b) return a + b end)))
	assert(test({ 6, 7, 8 }, fn.zip_with(function(a) return a + 5 end, { 1, 2, 3 })))
	assert(test({ 4, 6 }, fn.zip_with(function(a, b) return a + b end, { 1, 2 }, { 3, 4 })))
	assert(test({ 9, 12 }, fn.zip_with(function(a, b, c) return a + b + c end, { 1, 2 }, { 3, 4 }, { 5, 6 })))
	assert(test({ 12, 15 }, fn.zip_with(function(a, b, c) return a + b + c end, { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8 })))

	print("LibFunctional-1.0: tests passed")
end)()
