local path_m = {}

function path_m.is_valid(path)
   if not string.find(path, "\n") then
      return true
   end
end

function path_m.is_empty(path)
   return ((path == "") or not path)
end

function path_m.normalize(path)
   local stack = {}
   for entry in path_m.iterate(path) do
      if entry == "." then
      elseif entry == ".." then
         table.remove(stack)
      else
         table.insert(stack, entry)
      end
   end
    
   local normpath = "/" .. table.concat(stack, "/")
   local last = string.sub(path, -1)
   if (last == "/" or last == "." or last == "") and next(stack) then
      return normpath .. "/"
   else
      return normpath
   end
end

-- Path should be normalized
function path_m.basename(path)
   return string.match(path, '([^/]+)$')
end

function path_m.dirname(path)
   return string.match(path, '.*/')
end

function path_m.split(path)
   path = path_m.undir(path)
   return path_m.dirname(path), path_m.basename(path)
end

function path_m.dir(path)
   if not path_m.is_dir(path) then
      path = path .. "/"
   end
   return path
end

function path_m.undir(path)
   if path_m.is_dir(path) and not path_m.is_root(path) then
      path = string.sub(path, 1, -2)
   end
   return path
end

function path_m.frombase(base, path)
   if path_m.is_same(base, path) then
      return path_m.root()
   else
      local path_iter = path_m.iterate(path)
      for entry in path_m.iterate(base) do
         if entry ~= path_iter() then
            return nil
         end
      end

      local t = {}
      local entry = path_iter()
      while entry do
         table.insert(t, entry)
         entry = path_iter()
      end
      local res = "/" .. table.concat(t, "/")
      if path_m.is_dir(path) then
         res = path_m.dir(res)
      end
      return res
   end
end

function path_m.iterate(path)
   return string.gmatch(path, '[^/]+')
end

function path_m.root()
   return "/"
end

function path_m.is_dir(path)
   return (string.sub(path, -1) == "/")
end

function path_m.is_root(path)
   return (path == "/")
end

function path_m.is_same(path1, path2)
   return path1 == path2
end

return path_m
