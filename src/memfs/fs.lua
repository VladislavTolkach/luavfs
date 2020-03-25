local constants = require("constants")
local errno = require("errno")
local utils = require("utils")
local stat = require("stat")
local path_m = require("path")
local time = require("time")
local wrappers = require("wrappers")
local node_m = require("memfs.node")
local file_m = require("memfs.file")
local WrapFs = require("wrapfs")

local full_error = errno.full_error

local MemFs = {}

function Memfs:access(path, mode)
   if not (mode == constants.F_OK or mode == constants.W_OK 
      or mode == constants.R_OK or mode == constants.X_OK) then
      return full_error(errno.EINVAL)
   end

   local node, err = node_m.find_node(self._stor, path)
   if err then 
      return full_error(err)
   end

   if path_m.is_dir(path) and not stat.is_dir(node.mode) then
      return full_error(errno.ENOTDIR)
   end

   return true
end

MemFs.open = wrappers.open(function(self, path, flags, page_size)
   local file
   local basename = path_m.basename(path)
   local dir_node, err = node_m.find_node(self._stor, path_m.dirname(path))  
   if err then 
      return full_error(err)
   end

   local node, err = node_m.lookup(dir_node, basename)
   if node then
      if stat.is_dir(node.mode) then
         return full_error(errno.EISDIR)
      else
         return file_m.new(self, node, flags)
      end
   end

   if not flags.create then
      return full_error(err)
   end

   if path_m.is_empty(basename) then
      return full_error(errno.EINVAL)
   end
     
   if type(page_size) ~= "number" then
      page_size = nil
   end
   node, err  = node_m.add_node(self._stor, dir_node, basename, constants.REG, 
      page_size
   )
   if err then 
      return full_error(err)
   end

   return file_m.new(self, node, flags)
end)

function MemFs:mkdir(path)
   local dirname, basename = path_m.split(path)
   local dir_node, err = node_m.find_node(self._stor, dirname)
   if not dir_node then 
      return full_error(err) 
   end

   if path_m.is_empty(basename) then
      return full_error(errno.EINVAL)
   end

   local _, err = node_m.lookup(dir_node, basename)
   if not err then
      return full_error(errno.EEXIST)
   end

   local n, err = node_m.add_node(self._stor, dir_node, basename, constants.DIR)
   if n then 
      local t = time()
      dir_node.ctime = t
      dir_node.mtime = t
      return true
   else
      return full_error(err)
   end
end

function MemFs:iterdir(path)
   local node, err = node_m.find_node(self._stor, path)
   if not node then 
      return full_error(err)
   end

   if not stat.is_dir(node.mode) then
      return full_error(errno.ENOTDIR)
   end

   node.atime = time()
   return node_m.iterate_names(node)
end

function MemFs:rmdir(path)
   local dirname, basename = path_m.split(path)
   local dir_node, err = node_m.find_node(self._stor, dirname)
   if err then 
      return full_error(err)
   end
   if not stat.is_dir(dir_node.mode) then
      return full_error(errno.ENOTDIR)
   end

   local victim, err = node_m.lookup(dir_node, basename)
   if err then 
      return full_error(err)
   end
   if not stat.is_dir(victim.mode) then
      return full_error(errno.ENOTDIR)
   end

   if node_m.is_empty(victim) then
      return full_error(errno.ENOTEMPTY)
   end

   if victim == self._stor.root then
      return full_error(errno.EBUSY)
   end
   
   err = node_m.remove_node(dir_node, basename)
   if not err then
      local t = time()
      dir_node.ctime = t
      dir_node.mtime = t
      victim.ctime = t
      return true
   else
      return full_error(err)
   end
end

function MemFs:stat(path)
   local node, err = node_m.find_node(self._stor, path)
   if node then
      -- TODO 
      return {
         dev = nil,
         ino = nil,
         mode = node.mode,
         nlink = node.nlink,
         uid = nil,
         gid = nil,
         rdev = nil,
         access = node.atime,
         modification = node.mtime,
         change = node.ctime,
         size = node.data.size,
         permissions = nil,
         block = nil,
         blksize = nil,
      }
   else
      return full_error(err)
   end
end

function MemFs:utime(path, atime, mtime)
   local node, err = node_m.find_node(self._stor, path)
   if node then 
      if atime then
         node.atime = atime
      end
      if mtime then
         node.mtime = mtime
      end
      return true
   else 
      return full_error(err)
   end
end

function MemFs:link(old_path, new_path)
   return full_error(errno.EPERM)
end


function MemFs:unlink(path)
   local dirname, basename = path_m.split(path)
   local dir_node, err = node_m.find_node(self._stor, dirname)
   if err then 
      return full_error(err)
   end

   if not stat.is_dir(dir_node.mode) then
      return full_error(errno.ENOTDIR)
   end

   local victim, err = node_m.lookup(dir_node, basename)
   if err then 
      return full_error(err)
   end
   if path_m.is_dir(path) or stat.is_dir(victim.mode) then
      return full_error(errno.EISDIR)
   end
   
   err = node_m.remove_node(dir_node, basename)
   if not err then
      local t = time()
      dir_node.ctime = t
      dir_node.mtime = t
      victim.ctime = t
      return true
   else
      return full_error(err)
   end
end

function MemFs:rename(old_path, new_path)
end

local function create_storage(stor)
   stor.root = node_m.root() 
   stor.cfg = {}
   stor.cfg.page_size = 4096
   return stor
end

function MemFs.new(storage, config)
   local fs = {}
   fs._stor = create_storage(storage)
   fs._files = {}
   fs._cfg = config --TODO
   setmetatable(fs, {__index = MemFs})
   return WrapFs(fs)
end

utils.make_callable(MemFs, MemFs.new)


return MemFs
