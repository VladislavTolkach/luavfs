local utils = {}

function utils.find_free_index(t)
   local found
   local max_index = table.maxn(t)
   for i = 1, max_index do 
      if not t[i] then 
         found = i
         break 
      end 
   end

   if not found then 
      return max_index + 1 
   end

   return found
end

function utils.make_callable(cls, constructor)
   setmetatable(cls, {
      __call = function(cls, ...)
         return constructor(...)
      end,
   })
end

return utils
