local errno = require("errno")
local utils = require("utils")
local stat = require("stat")
local path_m = require("path")
local WrapFs = require("wrapfs")

local MountFs = {}

setmetatable(MountFs, {__index = WrapFs})


local function find_mountpoint(self, path)
   local node = self._mount_root_node
   local mp = node
   for entry in path_m.iterate(path) do
      node = node.nodes[entry]
      if node then 
         if node.fs then
            mp = node
         end
      else
         break
      end
   end

   return mp
end

local function add_mountpoint(self, fs, path, nearest_mp)
   local node = nearest_mp
   for entry in path_m.iterate(path_m.frombase(nearest_mp.path, path)) do
      if not node.nodes[entry] then
         local new_node = {
            nodes = {},
         }
         node.nodes[entry] = new_node
      end
      node = new_node
   end

   node.fs = fs
   node.path = path
end

function MountFs:_delegate(path)
   if self._is_single_fs then
      return self._fs, path
   else
      local mp = find_mountpoint(self, path)
      return mp.fs, path_m.frombase(mp.path, path)
   end
end

function MountFs:mount(path, mounted_fs, opt)
   -- TODO type check, check fs, opt, overlap mount, ...
   errutils.type_check("mount", 1, path, "string")
   errutils.type_check("mount", 2, mounted_fs, "table")
   errutils.type_check("mount", 3, opt, "table")
   path = path_m.undir(path_m.normalize(path))
   local fs, rel_path = self._delegate(path)
   local st, err = fs:stat(rel_path)
   if not st then
      return errno.full_error(err)
   end

   if not stat.is_dir(st.mode) then
      return errno.full_error(errno.ENOTDIR)
   end

   local mp = find_mountpoint(self, path)
   if path_m.is_same(mp.path, path) then 
      if path_m.is_root(mp.path) and self._allow_remount_rootfs then
         mp.fs = mounted_fs
         self._allow_remount_rootfs = false
         return true
      else
         return errno.full_error(errno.EBUSY)
      end
   else
      add_mountpoint(self, mounted_fs, rel_path, mp)
      return true
   end
end

function MountFs.new(root_fs)
   local fs = root_fs or DummyFs()
   local mountfs = {
      _fs = root_fs,
      _mount_root_node = {
         fs = root_fs,
         path = path_m.root(),
         nodes = {},
      },
      _is_single_fs = true,
   }

   if root_fs then 
      mountfs._allow_remount_rootfs = true
   end

   setmetatable(mountfs, {__index = MountFs})
end

utils.make_callable(MountFs, MountFs.new)

return MountFs
