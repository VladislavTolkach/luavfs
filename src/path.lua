local path_m = {}

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

function path_m.basename(path)
   return string.match(path, '([^/]+)$')
end

function path_m.dirname(path)
   return string.match(path, '.*/')
end

function path_m.split(path)
   if path_m.is_dir(path) and not path_m.is_root(path) then
      path = string.sub(path, 1, -2)
   end
   return path_m.dirname(path), path_m.basename(path)
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

function path_m.is_empty(path)
   return ((path == "") or not path)
end

return path_m
