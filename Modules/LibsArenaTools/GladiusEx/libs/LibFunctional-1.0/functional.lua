local version = 2
local lib

-- allow it to work outside of wow for testing purposes
if LibStub then
	lib = LibStub:NewLibrary("LibFunctional-1.0", version)
else
	lib = {}
end

if not lib then return end

-- globals
local tinsert, tsort, tconcat = table.insert, table.sort, table.concat
local pairs, next, select, type, unpack, loadstring = pairs, next, select, type, unpack, loadstring
local math_min, math_max, math_floor, math_random = math.min, math.max, math.floor, math.random

local function identity(x)
	return x
end

--- Returns a new table with the keys and values of all the passed tables.
-- If a key is present in more than one of the tables, the value from the rightmost table in the argument list is used.
-- @param ... any number of input tables.
local function merge(...)
	local r = {}
	for i = 1, select("#", ...) do
		for k, v in pairs(select(i, ...)) do
			r[k] = v
		end
	end
	return r
end

--- Returns a list of keys in the table //tbl//.
-- @param tbl the input table.
local function keys(tbl)
	local r = {}
	for k, _ in pairs(tbl) do
		tinsert(r, k)
	end
	return r
end

--- Returns a list of values in the table //tbl//.
-- @param tbl the input table.
local function values(tbl)
	local r = {}
	for _, v in pairs(tbl) do
		tinsert(r, v)
	end
	return r
end

--- Returns a list of ##{ key, value }## pairs in the table //tbl//.
-- This function is equivalent to ##zip(keys(tbl), values(tbl))##.
-- @name pairs
-- @param tbl the input table.
local function table_pairs(tbl)
	local r = {}
	for k, v in pairs(tbl) do
		tinsert(r, { k , v })
	end
	return r
end

--- Returns the number of items in the table //tbl//.
-- @name size
-- @param tbl the input table.
local function table_size(tbl)
	local count = 0
	local v = nil
	while true do
		v = next(tbl, v)
		if not v then return count end
		count = count + 1
	end
end

--- Returns true if the table //tbl1// has the same keys and values than the table //tbl2//.
-- @paramsig tbl1, tbl2[, deep]
-- @param tbl1 first table.
-- @param tbl2 second table.
-- @param deep optional, if true, table values inside the tables are compared recursively, otherwise a shallow comparison is made. Note that if the tables contains cyclic references this function will fail to perform a deep comparison.
local function equal(tbl1, tbl2, deep)
	if table_size(tbl1) ~= table_size(tbl2) then return false end
	for k, v in pairs(tbl1) do
		if deep and type(v) == "table" then
			if not equal(v, tbl2[k], deep) then return false end
		elseif tbl2[k] ~= v then return false end
	end
	return true
end

--- Returns a copy of the table //tbl// with its values as keys and its keys as values.
-- @param tbl the input table.
local function invert(tbl)
	local r = {}
	for k, v in pairs(tbl) do
		r[v] = k
	end
	return r
end

--- Returns a copy of the table //tbl//.
-- @paramsig tbl[, deep]
-- @param tbl the input table.
-- @param deep optional, if true, table values inside the table are copied recursively, otherwise a shallow copy is made. Note that if the tables contains cyclic references this function will fail to perform a deep copy.
local function clone(tbl, deep)
	local r = {}
	for k, v in pairs(tbl) do
		if deep and type(v) == "table" then
			r[k] = clone(v, deep)
		else
			r[k] = v
		end
	end
	return r
end

--- Returns a list containing the numbers from //start// to //stop// (including //stop//) with step //step//.
-- If omitted, //start// and //step// default to 1.
-- @paramsig [start], stop[, step]
local function range(a1, a2, a3)
	local start = a2 and a1 or 1
	local stop = a2 and a2 or a1
	local step = a3 or 1
	local r = {}
	local p = 1
	for i = start, stop, step do
		r[p] = i
		p = p + 1
	end
	return r
end

--- Returns a copy of a portion of the list //list//.
-- @paramsig list, begin[, end]
-- @param list the input list.
-- @param begin the first index to copy. If negative, indicates an offset from the end of the list.
-- @param end optional, the last index to copy. If omitted, the list is copied through the end. If negative, indicates an offset from the end of the list.
local function slice(l, b, e)
	local r = {}
	local len = #l
	b = b or 1
	e = e or len
	b = b < 0 and (len + b + 1) or b
	e = e < 0 and (len + e) or e
	for i = b, e do
		r[i - b + 1] = l[i]
	end
	return r
end

--- Shuffles the list //list// in-place using the Fisher–Yates algorithm and returns it.
-- @param list the input list.
local function shuffle_inplace(list)
	local j = #list
	while (j > 0) do
		local i = math_random(j)
		local tmp = list[i]
		list[i] = list[j]
		list[j] = tmp
		j = j - 1
	end
	return list
end

--- Returns a copy of the list //list// shuffled using the Fisher–Yates algorithm.
-- @param list the input list.
local function shuffle(list)
	return shuffle_inplace(clone(list))
end

--- Returns a copy of the list //list// with any nested lists flattened to a single level.
-- @paramsig list[, shallow]
-- @param list the input list.
-- @param shallow optional, if set to true only flattens the first level.
local function flatten(l, shallow, output)
	local r = output or {}
	local len = #l
	for i = 1, len do
		local v = l[i]
		if type(v) == "table" then
			local lenj = #v
			for j = 1, lenj do
				local vj = v[j]
				if type(vj) == "table" and not shallow then
					flatten(vj, shallow, r)
				else
					tinsert(r, vj)
				end
			end
		else
			tinsert(r, v)
		end
	end
	return r
end

--- Calls repeatedly the function //fn// with each value of the list //list//.
-- **aliases**: //for_each//
-- @param list the input list.
-- @param fn the function called with each value.
local function each(list, fn)
	local len = #list
	for i = 1, len do
		local v = list[i]
		fn(v)
	end
	return list
end

--- Returns a new list with the results of //fn// applied to all items in the list //list//.
-- @param list the input list.
-- @param fn the function called with each value.
local function map(list, fn)
	local r = {}
	local len = #list
	for i = 1, len do
		r[i] = fn(list[i])
	end
	return r
end

--- Returns a list of values in the list //list// that pass a truth test //fn//.
-- @param list the input list.
-- @param fn the truth test function.
local function filter(list, fn)
	local r = {}
	local len = #list
	for i = 1, len do
		if fn(list[i]) then
			tinsert(r, list[i])
		end
	end
	return r
end

--- Returns a reversed copy of the list //list//.
-- @param list the input list.
local function reverse(list)
	local r = {}
	local len = #list
	for i = 1, len do
		r[i] = list[len - i + 1]
	end
	return r
end

--- Returns true if the value //value// is present in the list //list//, false otherwise.
-- **aliases**: //elem//
-- @param list the input list.
-- @param value the value to search for.
-- @param fn an optional function to apply to each value in the list before comparing it to //value//.
local function contains(list, value, fn)
	local fn = fn or identity
	local len = #list
	for i = 1, len do
		if fn(list[i]) == value then
			return true
		end
	end
	return false
end

--- Returns the first value and its index in list //list// that is equal to any of the values passed.
-- @param list the input list.
-- @param ... one or more values to search for.
local function find_first_of(list, ...)
	local vs = { ... }
	local len = #list
	for i = 1, len do
		local lv = list[i]
		if contains(vs, lv) then
			return lv, i
		end
	end
end

--- Returns the last value and its index in list //list// that is equal to any of the values passed.
-- @param list the input list.
-- @param ... one or more values to search for.
local function find_last_of(list, ...)
	local vs = { ... }
	local len = #list
	for i = len, 1, -1 do
		local lv = list[i]
		if contains(vs, lv) then
			return lv, i
		end
	end
end

--- Returns the first value and its index in list //list// that passes the truth test //fn//.
-- @param list the input list.
-- @param fn the truth test function.
local function find_if(list, fn)
	local len = #list
	for i = 1, len do
		local v = list[i]
		if fn(v) then
			return v, i
		end
	end
end

--- Performs a binary search on sorted list //list// for value //value// and returns the index at which value should be inserted.
-- @paramsig list, value[, fn]
-- @param list the input sorted list.
-- @param value the value to search for.
-- @param fn an optional function that is applied to each value in the list before performing the comparison.
local function sorted_index(list, value, fn)
	fn = fn or identity
	local lo = 1
	local hi = #list
	while lo < hi do
		local mid = math_floor((lo + hi) / 2)
		local mid_v = fn(list[mid])
		if mid_v == value then
			return mid
		elseif mid_v < value then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	return lo
end

--- Performs a binary search on sorted list //list// for value //value// and returns its index and value if found
-- @paramsig list, value[, fn]
-- @param list the input sorted list.
-- @param value the value to search for.
-- @param fn an optional function that is applied to each value in the list before performing the comparison.
local function binary_search(list, value, fn)
	local i = sorted_index(list, value, fn)
	local li = list[i]
	local lv
	
	if fn then
		lv = fn(li)
	else
		lv = li
	end

	if lv == value then
		return i, li
	end
end

--- Inserts a value //value// in a sorted list //list// and returns it.
-- @paramsig list, value[, fn]
-- @param list the input sorted list.
-- @param value the value to insert.
-- @param fn an optional function that is applied to each value in the list before performing the comparison.
local function sorted_insert(list, value, fn)
	local i = sorted_index(list, value, fn)
	tinsert(list, i, value)
	return list
end

--- Returns a reduction of the list //list// based on the left associative application of the function //fn//.
-- **aliases**: //foldl//
-- @paramsig list, fn[, initial]
-- @param list the input list.
-- @param fn a function receiving two values representing the result of the previous application of this function and the next value in the list //list//.
-- @param initial an optional initial value to be passed together with the first value of the list //list// to the function //fn//. If omitted, the first call is passed the two first values in the list //list// instead.
local function reduce(list, fn, initial)
	local s = initial and 1 or 2
	local r = initial and initial or list[1]
	local len = #list
	for i = s, len do
		r = fn(r, list[i])
	end
	return r
end

--- Returns a reduction of the list //list// based on the right associative application of the function //fn//.
-- **aliases**: //foldr//
-- @paramsig list, fn[, initial]
-- @param list the input list.
-- @param fn a function receiving two values representing the result of the previous application of this function and the previous value in the list //list//.
-- @param initial an optional initial value to be passed together with the last value of the list //list// to the function //fn//. If omitted, the first call is passed the two last values in the list //list// instead.
local function reduce_right(list, fn, initial)
	local s = initial and #list or #list - 1
	local r = initial and initial or list[#list]
	for i = s, 1, -1 do
		r = fn(r, list[i])
	end
	return r
end

--- Returns a sum of all the values in the list //list//.
-- This function is equivalent to ##reduce(list, function(a, b) return a + b end)##.
-- @param list the input list.
local function sum(list)
	return reduce(list, function(a, b) return a + b end)
end

--- Returns the minimum value in the list //list//.
-- This function is equivalent to ##reduce(list, math.min)##.
-- @param list the input list.
local function min(list)
	return reduce(list, math_min)
end

--- Returns the maximum value in the list //list//.
-- This function is equivalent to ##reduce(list, math.max)##.
-- @param list the input list.
local function max(list)
	return reduce(list, math_max)
end

--- Performs an in-place sort of the list //list// and returns it.
-- @paramsig list[, comp]
-- @param list the input list.
-- @param comp an optional comparison function that receives two values and returns true when the first is less than the second.
local function sort_inplace(list, comp)
	tsort(list, comp)
	return list
end

--- Returns a sorted copy of the list //list//.
-- @paramsig list[, comp]
-- @param list the input list.
-- @param comp an optional comparison function that receives two values and returns true when the first is less than the second.
local function sort(list, comp)
	local r = clone(list)
	tsort(r, comp)
	return r
end

--- Returns true if all the values in the list //list// satisfy the truth test //fn//, false otherwise.
-- **aliases**: //every//
-- @param list the input list.
-- @param fn the truth test function.
local function all(list, fn)
	local len = #list
	for i = 1, len do
		local v = list[i]
		if not fn(v) then
			return false
		end
	end
	return true
end

--- Returns true if any value in the list //list// satisfies the truth test //fn//, false otherwise.
-- **aliases**: //some//
-- @param list the input list.
-- @param fn the truth test function.
local function any(list, fn)
	local len = #list
	for i = 1, len do
		local v = list[i]
		if fn(v) then
			return true
		end
	end
	return false
end

--- Returns a list containing the concatenation of all the input lists.
-- @param ... any number of input lists.
local function concat(...)
	local r = {}
	local n = select("#", ...)
	for a = 1, n do
		local l = select(a, ...)
		local len = #l
		for i = 1, len do
			tinsert(r, l[i])
		end
	end
	return r
end

--- Returns a copy of the list //list// with any duplicate values removed.
-- @paramsig list[, is_sorted[, fn]]
-- @param list the input list.
-- @param is_sorted an optional argument specifying if the list is sorted, allowing to use a more efficient algorithm.
-- @param fn an optional function that is applied to each value in the list before performing the comparison.
local function uniq(list, is_sorted, fn)
	local lm = fn and map(list, fn) or list
	local r = {}
	local seen = {}
	local len = #list
	for i = 1, len do
		local v = lm[i]
		local newv = is_sorted and (i == 1 or lm[i - 1] ~= v) or not contains(seen, v)
		if newv then
			tinsert(seen, v)
			tinsert(r, list[i])
		end
	end
	return r
end

--- Returns a list containing all the different values present in the input lists.
-- @param ... any number of input lists.
local function union(...)
	return uniq(concat(...))
end

local function get_set_params(...)
	local fn = identity
	local a = select(1, ...)
	local others
	if type(a) == "function" then
		fn = a
		a = select(2, ...)
		others = { select(3, ...) }
	else
		others = { select(2, ...) }
	end

	return fn, a, others
end

--- Returns a list containing all the items in the first list that are not present in any of the rest.
-- @paramsig [fn, ]list1, [list2...]
-- @param fn an optional function to apply to each value in the list before performing the comparison.
-- @param list two or more input lists.
local function difference(...)
	local fn, a, others = get_set_params(...)
	return filter(a, function(xa)
		return all(others, function(other)
			return not contains(other, fn(xa), fn)
		end)
	end)
end

--- Returns a list containing all the items that are present in all of the input lists.
-- If the first list passed contains the same value multiple times, it may appear multiple times in the output list. Use //uniq// on the first list if you want to prevent this.
-- @paramsig [fn, ]list1, [list2...]
-- @param fn an optional function to apply to each value in the list before performing the comparison.
-- @param list two or more input lists.
local function intersection(...)
	local fn, a, others = get_set_params(...)
	return filter(a, function(xa)
		return all(others, function(other)
			return contains(other, fn(xa), fn)
		end)
	end)
end

--- Returns a list constructed from the result of an iterator function.
-- @paramsig [fn, ]f, s, var
-- @param fn an optional function that is applied to the values returned by the iterator before adding them to the list.
-- If omitted, the default function packs all the values returned by the iterator into a list.
-- @param f the values returned by an iterator function.
-- @param s the values returned by an iterator function.
-- @param var the values returned by an iterator function.
local function from_iterator(...)
	local tr
	local f, s, var

	if select("#", ...) == 4 then
		tr = select(1, ...)
		f = select(2, ...)
		s = select(3, ...)
		var = select(4, ...)
	else
		tr = function(...) return { ... } end
		f = select(1, ...)
		s = select(2, ...)
		var = select(3, ...)
	end

	local function mtr(...)
		var = select(1, ...)
		if var  == nil then
			return nil
		else
			return tr(...)
		end
	end

	local r = {}
	local n = 1
	while true do
		local v = mtr(f(s, var))
		if var == nil then break end
		r[n] = v
		n = n + 1
	end

	return r
end

--- Takes any number of lists and returns a new list where each element is a list of the values in all of the passed lists at that position.
-- If one list is shorter than the others, excess elements of the longer lists are discarded.
-- @param ... any number of input lists.
-- @see unzip
local function zip(...)
	local ls = { ... }
	local n = #ls
	if n == 0 then return {} end
	local len = reduce(ls, function(r, v) return math_min(r, #v) end, #ls[1])
	local r = {}
	for i = 1, len do
		local v = {}
		for j = 1, n do
			v[j] = ls[j][i]
		end
		r[i] = v
	end
	return r
end

--- Undoes a zip operation.
-- @param list a list of lists.
-- @see zip
local function unzip(list)
	return unpack(zip(unpack(list)))
end

--- Takes any number of lists and returns a new list where each element is the result of calling the function //fn// with the values in all of the passed lists at that position.
-- If one list is shorter than the others, excess elements of the longer lists are discarded.
-- @param fn a function taking as many parameters as lists are passed to zip_with and returning a value to be inserted in the resulting list.
-- @param ... any number of input lists.
local function zip_with(fn, ...)
	local ls = { ... }
	local n = #ls
	if n == 0 then return {} end
	local len = reduce(ls, function(r, v) return math_min(r, #v) end, #ls[1])
	local r = {}
	local v = {}
	for i = 1, len do
		for j = 1, n do
			v[j] = ls[j][i]
		end
		r[i] = fn(unpack(v))
	end
	return r
end

--- Returns a function //g// such as calling //g(p1, p2, .. pn)// is equivalent to calling //fn(arg1, arg2, .. argn, p1, p2, .. pn)//.
-- @paramsig fn, arg1[, arg2...]
-- @param fn the input function.
-- @param "arg1[, arg2...]" one or more arguments to be bound.
local function bind(fn, ...)
	local anames = tconcat(map(range(select("#", ...)), function(x) return "a"..x end), ",")
	return loadstring(
		[[return function(fn, ]] .. anames .. [[)
			return function(...)
				return fn(]] .. anames .. [[, ...)
			end
		end]])()(fn, ...)
end

--- Returns a function //g// such as calling //g(p1, p2, .. pn)// is equivalent to calling //fn(p1, p2, .. pnth, arg1, arg2, .. argn, pnth+1, pnth+2, .. pnth+n)//.
-- @paramsig fn, nth, arg1[, arg2...]
-- @param fn the input function.
-- @param nth the position of the first argument to be bound.
-- @param "arg1[, arg2...]" one or more arguments to be bound.
local function bind_nth(fn, nth, ...)
	local pnames = tconcat(map(range(nth - 1), function(x) return "p"..x end), ",")
	local anames = tconcat(map(range(select("#", ...)), function(x) return "a"..x end), ",")
	if nth > 1 then	pnames = pnames .. "," end
	return loadstring(
		[[return function(fn, ]] .. anames .. [[)
			return function(]] .. pnames .. [[ ...)
				return fn(]] .. pnames .. anames .. [[, ...)
			end
		end]])()(fn, ...)
end

-- setup library table

lib.all = all
lib.any = any
lib.binary_search = binary_search
lib.bind = bind
lib.bind_nth = bind_nth
lib.clone = clone
lib.concat = concat
lib.contains = contains
lib.difference = difference
lib.each = each
lib.elem = contains
lib.equal = equal
lib.every = all
lib.filter = filter
lib.find_first_of = find_first_of
lib.find_if = find_if
lib.find_last_of = find_last_of
lib.flatten = flatten
lib.foldl = reduce
lib.foldr = reduce_right
lib.for_each = each
lib.from_iterator = from_iterator
lib.intersection = intersection
lib.invert = invert
lib.keys = keys
lib.map = map
lib.max = max
lib.merge = merge
lib.min = min
lib.pairs = table_pairs
lib.range = range
lib.reduce = reduce
lib.reduce_right = reduce_right
lib.reverse = reverse
lib.shuffle = shuffle
lib.shuffle_inplace = shuffle_inplace
lib.size = table_size
lib.slice = slice
lib.some = any
lib.sort = sort
lib.sort_inplace = sort_inplace
lib.sorted_index = sorted_index
lib.sorted_insert = sorted_insert
lib.sum = sum
lib.union = union
lib.uniq = uniq
lib.unzip = unzip
lib.values = values
lib.zip = zip
lib.zip_with = zip_with

-- allows it to work as a lua module outside of wow
-- shouldn't have any side effects inside wow
return lib
