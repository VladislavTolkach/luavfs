local errno = require("errno")

local DummyFs = {}


local fs = setmetatable({}, {__index = DummyFs})

function DummyFs.new()
   return fs
end 

setmetatable(DummyFs, {
   __call = function(cls, ...)
      return cls.new(...)
   end,
   __index = function(k, v)
      return function()
         return errno.full_error(errno.ENOSYS)
      end
   end,
})

return DummyFs 
