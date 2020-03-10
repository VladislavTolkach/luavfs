local errno = require("errno")

local DummyFs = {}

local function ret()
   return nil, errno.full_error(errno.ENOSYS)
end

local function noret()
   return errno.full_error(errno.ENOSYS)
end

DummyFs.access = noret
DummyFs.open = ret
DummyFs.mkdir = noret
DummyFs.rmdir = noret
DummyFs.rename = noret
DummyFs.utime = noret
DummyFs.stat = ret
DummyFs.link = noret
DummyFs.unlink = noret
DummyFs.iterdir = ret
DummyFs.opendir = ret


function DummyFs.new()
   return DummyFs
end 

setmetatable(DummyFs, {
   __call = function(cls, ...)
      return cls.new(...)
   end,
})

return DummyFs 
