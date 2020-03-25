local errno = require("errno")
local errutils = require("errutils")
local utils = require("utils")
local path_m = require("path")
local stat = require("stat")
local FsBase = require("fsbase")

local WrapFs = {}
setmetatable(WrapFs, {__index = FsBase})

function WrapFs:access(path, mode)
   errutils.type_check("access", 1, path, "string")
   errutils.type_check("access", 2, mode, "number")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:access(path, mode)
end

function WrapFs:open(path, mode, ...)
   errutils.type_check("open", 1, path, "string")
   errutils.type_check("open", 2, mode, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:open(path, mode, ...)
end

function WrapFs:mkdir(path)
   errutils.type_check("mkdir", 1, path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:mkdir(path)
end

function WrapFs:rmdir(path)
   errutils.type_check("rmdir", 1, path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:rmdir(path)
end

function WrapFs:rename(old_path, new_path)
   errutils.type_check("rename", 1, old_path, "string")
   errutils.type_check("rename", 2, new_path, "string")
   if not path_m.is_valid(old_path) then return errno.full_error(errno.EINVAL) end
   if not path_m.is_valid(new_path) then return errno.full_error(errno.EINVAL) end
   old_path = path_m.normalize(old_path)
   new_path = path_m.normalize(new_path)
   local fs, old_path = self:_delegate(old_path)
   local fs2, new_path = self:_delegate(new_path)
   if fs == fs2 then
      return fs:rename(old_path, new_path)
   else
      return errno.full_error(errno.EXDEV)
   end
end


function WrapFs:utime(path, atime, mtime)
   errutils.type_check("utime", 1, old_path, "string")
   if atime then
      errutils.type_check("utime", 2, atime, "number")
   end
   if mtime then
      errutils.type_check("utime", 3, mtime, "number")
   end
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:utime(path, atime, mtime)
end

function WrapFs:stat(path)
   errutils.type_check("stat", 1, old_path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:stat(path)
end

function WrapFs:link(old_path, new_path)
   errutils.type_check("link", 1, old_path, "string")
   errutils.type_check("link", 2, new_path, "string")
   if not path_m.is_valid(old_path) then return errno.full_error(errno.EINVAL) end
   if not path_m.is_valid(new_path) then return errno.full_error(errno.EINVAL) end
   old_path = path_m.normalize(old_path)
   new_path = path_m.normalize(new_path)
   local fs, old_path = self:_delegate(old_path)
   local fs2, new_path = self:_delegate(new_path)
   if fs == fs2 then
      return fs:link(old_path, new_path)
   else
      return errno.full_error(errno.EXDEV)
   end
end

function WrapFs:unlink(path)
   errutils.type_check("unlink", 1, path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:unlink(path)
end

function WrapFs:iterdir(path)
   errutils.type_check("iterdir", 1, path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   return fs:iterdir(path)
end

function WrapFs:opendir(path)
   errutils.type_check("opendir", 1, path, "string")
   if not path_m.is_valid(path) then return errno.full_error(errno.EINVAL) end
   path = path_m.normalize(path)
   local fs, path = self:_delegate(path)
   local st, err = fs:stat(path)

   if not st then
      return errno.full_error(err)
   end

   if stat.is_dir(st.mode) then
      return self:_opendir(path_m.undir(path))
   else
      return errno.full_error(errno.ENOTDIR)
   end
end


function WrapFs:mount()
   return errno.full_error(errno.ENOSYS)
end

function WrapFs:_opendir(path)
   local fs = WrapFs.new(self._fs)
   fs._pathbase = fs._pathbase .. path
   return fs
end

function WrapFs:_delegate(path)
   return self._fs, self._pathbase .. path
end

function WrapFs.new(fs)
   local wrapfs = {
      _fs = fs,
      _pathbase = "",
   }
   return setmetatable(wrapfs, {__index = WrapFs})
end

utils.make_callable(WrapFs, WrapFs.new)

return WrapFs
