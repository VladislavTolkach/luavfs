local errno = require("errno")

local FsBase = {}

setmetatable(FsBase, {
   __index = function(k, v)
      return function()
         return errno.full_error(errno.ENOSYS)
      end
   end,
})

return FsBase  
