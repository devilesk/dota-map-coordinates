require("libraries/functional")
require("libraries/util")

List = class(
  {},
  {
      __class__name = "List"
  }
)

function List:constructor(t)
  self.items = {}
  if instanceof(t, List) then
    self:Copy(t)
  elseif istable(t) then
    self:SetItems(t)
  end
end

function List:Items()
  return self.items
end

function List:SetItems(items)
  assert(istable(items), "SetItems() argument is not a table")
  self.items = items
  return self
end

function List:Size()
  return #self:Items()
end

function List:IsEmpty()
  return self:Size() == 0
end

function List:Iter(start, num_iterations)
  local start = start or 1
  local iterations_left = num_iterations or 1
  assert(isnumber(start), "Iter() first argument is not a number")
  assert(start <= self:Size() or self:Size() == 0, "Iter() start greater than size of list")
  assert(isnumber(iterations_left), "Iter() second argument is not a number")
  local iter = function (a, i)
    if start - 1 == i then
      if iterations_left == 0 then
        return nil
      end
      iterations_left = iterations_left - 1
    end
    i = i + 1
    local v = a[i]
    i = i % #a
    if v then
      local j = i == 0 and #a or i
      return j, v
    end
  end
  return iter, self:Items(), start - 1
end

function List:Extract(f, g, ...)
  assert(isfunction(f), "Min() first argument not a function")
  assert(isfunction(g) or g == nil, "Min() second argument not a function")
  return tableextract(self:Items(), f, g, ...)
end

function List:Min(f, ...)
  assert(isfunction(f) or f == nil, "Min() first argument not a function")
  return tablemin(self:Items(), f, ...)
end

function List:Max(f, ...)
  assert(isfunction(f) or f == nil, "Max() first argument not a function")
  return tablemax(self:Items(), f, ...)
end

function List:Get(pos)
  assert(isnumber(pos), "Get() pos argument is not a number")
  return self:Items()[pos]
end

function List:GetRandom()
  return self:Get(math.random(self:Size()))
end

function List:Set(val, pos)
  self:Items()[pos] = val
  return self
end

function List:Swap(i, j)
  local temp = self:Get(i)
  self:Set(self:Get(j), i)
  self:Set(temp, j)
  return self
end

function List:Slice(i, j, wrap)
  local newlist = List(slice(self:Items(), i, j))
  if wrap == true then
    local remainder = math.min(math.max(0, self:Size() - j), self:Size())
    if remainder > 0 then
      newlist:Push(slice(self:Items(), 1, remainder))
    end
  end
  return newlist
end

function List:First(j)
  j = j or 1
  return slice(self:Items(), 1, j)[1]
end

function List:Last(i)
  i = i or 1
  return slice(self:Items(), math.max(self:Size() - i + 1, 1))[1]
end

function List:Filter(f, ...)
  return List(ifilter(f, self:Items(), ...))
end

function List:Map(f, ...)
  return List(imap(f, self:Items(), ...))
end

function List:Each(f, ...)
  for k, v in self:Iter() do
    f(v, k, self, ...)
  end
end

function List:Any(f, ...)
  return any(f, self:Items(), ...)
end

function List:All(f, ...)
  return all(f, self:Items(), ...)
end

function List:Find(o, pos, ...)
  return tablefind(o, self:Items(), pos, ...)
end

function List:Count(o, ...)
  return count(o, self:Items(), ...)
end

function List:Contains(o)
  return contains(o, self:Items())
end

function List:IndexOf(o, pos)
  assert(istable(o), "IndexOf() first argument is not a table")
  local _, k = tablefind(o, self:Items(), pos)
  return k
end

function List:FindAll(o, ...)
  local func = o
  if not isfunction(o) then
    func = function (item)
      return equals(o, item)
    end
  end
  return self:Filter(func, ...)
end

function List:Peek()
  return self:Get(1)
end

function List:PeekBack()
  return self:Get(self:Size())
end

function List:Clear()
  self:SetItems({})
  return self
end

function List:Insert(t, pos)
  assert(isnumber(pos), "Insert() pos argument is not a number")
  table.insert(self:Items(), pos, t)
  return self
end

function List:InsertList(t, pos)
  assert(instanceof(t, List), "InsertList() first argument is not a List")
  for k, item in t:Iter() do
    self:Insert(item, pos + k - 1)
  end
  return self
end

function List:Push(t)
  return self:Insert(t, self:Size()+1)
end

function List:Unshift(t)
  return self:Insert(t, 1)
end

function List:PushList(t)
  assert(instanceof(t, List), "PushList() first argument is not a List")
  return self:InsertList(t, self:Size()+1)
end

function List:UnshiftList(t)
  assert(instanceof(t, List), "UnshiftList() first argument is not a List")
  return self:InsertList(t, 1)
end

function List:Copy(t)
  assert(instanceof(t, List), "Copy() argument is not a list")
  self:Clear()
  return self:InsertList(t, 1)
end

-- removes given item or item at given position
function List:Remove(item)
  for k, v in ipairs(self:Items()) do
    if v == item then
      return table.remove(self:Items(), k)
    end
  end
end

function List:RemoveAt(pos)
  assert(isnumber(pos), "RemoveAt() argument is not a number")
  assert(pos <= self:Size(), "RemoveAt() position greater than size of List")
  return table.remove(self:Items(), pos)
end

function List:Pop()
  return self:RemoveAt(self:Size())
end

function List:Shift()
  return self:RemoveAt(1)
end

function List:Reverse()
  reversetable(self:Items())
  return self
end

function List:Shuffle()
  shuffletable(self:Items())
  return self
end

function List:Sort(f)
  assert(isfunction(f) or f == nil, "Sort() argument is not a function")
  table.sort(self:Items(), f)
  return self
end

function List:Equals(list, f)
  local t = list
  if instanceof(list, List) then
    t = list:Items()
  end
  assert(istable(t), "Equals() first argument is not a List or table")
  return tableequals(self:Items(), t, f)
end

function List:Dump(f, ...)
  f = f or print
  for k, v in self:Iter() do
    print (k .. ":")
    f(v, ...)
  end
  return self
end

print( "list.lua is loaded." )