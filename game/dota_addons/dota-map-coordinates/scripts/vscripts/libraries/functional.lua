-- Functional Library
--
-- @file    functional.lua
-- @author  Shimomura Ikkei
-- @date    2005/05/18
--
-- @brief    porting several convenience functional utilities form Haskell,Python etc..

-- map(function, table)
-- e.g: map(double, {1,2,3})    -> {2,4,6}
function map(func, tbl, ...)
  assert(type(func) == "function", "map() first argument is not a function")
  assert(type(tbl) == "table", "map() second argument is not a table")
  local newtbl = {}
  for i, v in pairs(tbl) do
    newtbl[i] = func(v, i, tbl, ...)
  end
  return newtbl
end

-- imap(function, table)
-- e.g: imap(double, {1,2,3})    -> {2,4,6}
function imap(func, tbl, ...)
  assert(type(func) == "function", "imap() first argument is not a function")
  assert(type(tbl) == "table", "imap() second argument is not a table")
  local newtbl = {}
  for i, v in ipairs(tbl) do
    table.insert(newtbl,func(v, i, tbl, ...))
  end
  return newtbl
end

-- filter(function, table)
-- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
function filter(func, tbl, ...)
  assert(type(func) == "function", "filter() first argument is not a function")
  assert(type(tbl) == "table", "filter() second argument is not a table")
  local newtbl= {}
  for i, v in pairs(tbl) do
    if func(v, i, tbl, ...) then
      newtbl[i] = v
    end
  end
  return newtbl
end

-- ifilter(function, table)
-- e.g: ifilter(is_even, {1,2,3,4}) -> {2,4}
function ifilter(func, tbl, ...)
  assert(type(func) == "function", "ifilter() first argument is not a function")
  assert(type(tbl) == "table", "ifilter() second argument is not a table")
  local newtbl= {}
  for i, v in ipairs(tbl) do
    if func(v, i, tbl, ...) then
      table.insert(newtbl, v)
    end
  end
  return newtbl
end

-- head(table)
-- e.g: head({1,2,3}) -> 1
function head(tbl)
  assert(type(tbl) == "table", "head() first argument is not a table")
  return tbl[1]
end

-- tail(table)
-- e.g: tail({1,2,3}) -> {2,3}
--
-- XXX This is a BAD and ugly implementation.
-- should return the address to next porinter, like in C (arr+1)
function tail(tbl)
  assert(type(tbl) == "table", "tail() first argument is not a table")
  if table.getn(tbl) < 1 then
    return nil
  else
    local newtbl = {}
    local tblsize = table.getn(tbl)
    local i = 2
    while (i <= tblsize) do
      table.insert(newtbl, i-1, tbl[i])
      i = i + 1
    end
    return newtbl
  end
end

-- foldr(function, default_value, table)
-- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
function foldr(func, val, tbl, ...)
  assert(type(func) == "function", "foldr() first argument is not a function")
  assert(type(tbl) == "table", "foldr() third argument is not a table")
  for i, v in pairs(tbl) do
    val = func(val, v, i, tbl, ...)
  end
  return val
end

-- ifoldr(function, default_value, table)
-- e.g: ifoldr(operator.mul, 1, {1,2,3,4,5}) -> 120
function ifoldr(func, val, tbl, ...)
  assert(type(func) == "function", "ifoldr() first argument is not a function")
  assert(type(tbl) == "table", "ifoldr() third argument is not a table")
  for i, v in ipairs(tbl) do
    val = func(val, v, i, tbl, ...)
  end
  return val
end

-- reduce(function, table)
-- e.g: reduce(operator.add, {1,2,3,4}) -> 10
function reduce(func, tbl, ...)
  assert(type(func) == "function", "reduce() first argument is not a function")
  assert(type(tbl) == "table", "reduce() second argument is not a table")
  return foldr(func, head(tbl), tail(tbl), ...)
end

-- ireduce(function, table)
-- e.g: ireduce(operator.add, {1,2,3,4}) -> 10
function ireduce(func, tbl, ...)
  assert(type(func) == "function", "ireduce() first argument is not a function")
  assert(type(tbl) == "table", "ireduce() second argument is not a table")
  return ifoldr(func, head(tbl), tail(tbl), ...)
end

-- curry(f,g)
-- e.g: printf = curry(io.write, string.format)
--          -> function(...) return io.write(string.format(unpack(arg))) end
function curry(f,g)
  assert(type(f) == "function", "curry() first argument is not a function")
  assert(type(g) == "table", "curry() second argument is not a function")
  return function (...)
    return f(g(unpack(arg)))
  end
end

-- bind1(func, binding_value_for_1st)
-- bind2(func, binding_value_for_2nd)
-- @brief
--      Binding argument(s) and generate new function.
-- @see also STL's functional, Boost's Lambda, Combine, Bind.
-- @examples
--      local mul5 = bind1(operator.mul, 5) -- mul5(10) is 5 * 10
--      local sub2 = bind2(operator.sub, 2) -- sub2(5) is 5 -2
function bind1(func, val1)
  assert(type(func) == "function", "bind1() first argument is not a function")
  return function (val2)
    return func(val1, val2)
  end
end

function bind2(func, val2) -- bind second argument.
  assert(type(func) == "function", "bind2() first argument is not a function")
  return function (val1)
    return func(val1, val2)
  end
end
-- is(checker_function, expected_value)
-- @brief
--      check function generator. return the function to return boolean,
--      if the condition was expected then true, else false.
-- @example
--      local is_table = is(type, "table")
--      local is_even = is(bind2(math.mod, 2), 1)
--      local is_odd = is(bind2(math.mod, 2), 0)
is = function(check, expected)
  assert(type(check) == "function", "is() first argument is not a function")
  return function (...)
    if (check(unpack(arg)) == expected) then
      return true
    else
      return false
    end
  end
end

-- operator table.
-- @see also python's operator module.
operator = {
  mod = math.mod;
  pow = math.pow;
  add = function(n,m) return n + m end;
  sub = function(n,m) return n - m end;
  mul = function(n,m) return n * m end;
  div = function(n,m) return n / m end;
  gt  = function(n,m) return n > m end;
  lt  = function(n,m) return n < m end;
  eq  = function(n,m) return n == m end;
  le  = function(n,m) return n <= m end;
  ge  = function(n,m) return n >= m end;
  ne  = function(n,m) return n ~= m end;
}

-- enumFromTo(from, to)
-- e.g: enumFromTo(1, 10) -> {1,2,3,4,5,6,7,8,9}
-- TODO How to lazy evaluate in Lua? (thinking with coroutine)
enumFromTo = function (from,to)
  assert(type(from) == "number", "enumFromTo() first argument is not a number")
  assert(type(to) == "number", "enumFromTo() second argument is not a number")
  local newtbl = {}
  local step = bind2(operator[(from < to) and "add" or "sub"], 1)
  local val = from
  while val <= to do
    table.insert(newtbl, table.getn(newtbl)+1, val)
    val = step(val)
  end
  return newtbl
end

-- make function to take variant arguments, replace of a table.
-- this does not mean expand the arguments of function took,
-- it expand the function's spec: function(tbl) -> function(...)
function expand_args(func)
  assert(type(func) == "function", "expand_args() first argument is not a function")
  return function(...) return func(arg) end
end

print( "functional.lua is loaded." )