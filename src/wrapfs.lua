local errno = require("errno")
local errutils = require("errutils")
local path_m = require("path")

local WrapFs = {}

function WrapFs:access(path, mode)
   errutils.type_check("access", 1, path, "string")
   errutils.type_check("access", 2, mode, "number")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return errno.full_error(fs:access(path, mode))
end

function WrapFs:open(path, mode, ...)
   errutils.type_check("open", 1, path, "string")
   errutils.type_check("open", 2, mode, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   local ret, err = fs:open(path, mode, ...)
   return ret, errno.full_error(err)
end

function WrapFs:mkdir(path)
   errutils.type_check("mkdir", 1, path, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return errno.full_error(fs:mkdir(path))
end

function WrapFs:rmdir(path)
   errutils.type_check("rmdir", 1, path, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return errno.full_error(fs:rmdir(path))
end

function WrapFs:rename(old_path, new_path)
   errutils.type_check("rename", 1, old_path, "string")
   errutils.type_check("rename", 2, new_path, "string")
   old_path = path_m.normalize(old_path)
   new_path = path_m.normalize(new_path)
   local fs, old_path = self:_delegate(old_path)
   local fs2, new_path = self:_delegate(new_path)
   if fs == fs2 then
      return errno.full_error(fs:rename(old_path, new_path))
   else
      return errno.full_error(errno.EXDEV)
   end
end


function WrapFs:utime(path, atime, mtime)
   errutils.type_check("utime", 1, old_path, "string")
   errutils.type_check("utime", 2, atime, "number")
   errutils.type_check("utime", 3, mtime, "number")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return errno.full_error(fs:utime(path, atime, mtime))
end

function WrapFs:stat(path)
   errutils.type_check("stat", 1, old_path, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   local ret, err = fs:stat(path)
   return ret, errno.full_error(err)
end

function WrapFs:link(old_path, new_path)
   errutils.type_check("link", 1, old_path, "string")
   errutils.type_check("link", 2, new_path, "string")
   old_path = path_m.normalize(old_path)
   new_path = path_m.normalize(new_path)
   local fs, old_path = self:_delegate(old_path)
   local fs2, new_path = self:_delegate(new_path)
   if fs == fs2 then
      return errno.full_error(fs:link(old_path, new_path))
   else
      return errno.full_error(errno.EXDEV)
   end
end

function WrapFs:unlink(path)
   errutils.type_check("unlink", 1, old_path, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return errno.full_error(fs:unlink(path))
end

function WrapFs:iterdir(path)
   errutils.type_check("iterdir", 1, old_path, "string")
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   local ret, err = fs:iterdir(path)
   return ret, errno.full_error(err)
end

function WrapFs:mount()
   return errno.full_error(errno.ENOSYS)
end

function WrapFs:_delegate(path)
   return self._fs, path
end

function WrapFs.new(fs)
   local wrapfs = {
      _fs = fs
   }
   return setmetatable(wrapfs, {__index = WrapFs})
end

setmetatable(WrapFs, {
   __call = function(cls, ...)
      return cls.new(...)
   end,
})

return WrapFs
