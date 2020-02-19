local constants = require("constants")
local errno = require("errno")
local stat = require("stat")
local path_m = require("path")
local time = require("time")
local wrappers = require("wrappers")
local node_m = require("memfs.node")
local file_m = require("memfs.file")

local memfs = {}

local Memfs = {}


Memfs.open = wrappers.open(function(self, path, flags, page_size)
   local file
   path = path_m.normalize(path)
   local basename = path_m.basename(path)
   local dir_node, err = node_m.find_node(self._stor, path_m.dirname(path))  
   if err then 
      return nil, err
   end

   local node, err = node_m.lookup(dir_node, basename)
   if node then
      if stat.is_dir(node.mode) then
         return nil, errno.EISDIR
      else
         return file_m.new(self, node, flags)
      end
   end

   if not flags.create then
      return nil, err
   end

   if path_m.is_empty(basename) then
      return nil, errno.EINVAL
   end
      
   node = node_m.add_node(self._stor, dir_node, basename, constants.DIR, 
      page_size
   )
   return file_m.new(self, node, flags)
end)


local function mkdir(self, path)
   path = path_m.normalize(path)
   local dirname, basename = path_m.split(path)
   local dir_node, err = node_m.find_node(self._stor, dirname)
   if not dir_node then 
      return err 
   end

   if path_m.is_empty(basename) then
      return errno.EINVAL
   end

   local _, err = node_m.lookup(dir_node, basename)
   if not err then
      return errno.EEXIST
   end

   _, err = node_m.add_node(self._stor, dir_node, basename, constants.DIR)
   return err 
end

Memfs.mkdir = wrappers.err_noret(wrappers.arg_check(mkdir, "mkdir", "string"))


local function iter_dir(self, path)
   path = path_m.normalize(path)
   local node, err = node_m.find_node(self._stor, path)
   if not node then 
      return nil, err
   end

   if not stat.is_dir(node.mode) then
      return nil, errno.ENOTDIR
   end

   return node_m.iterate_names(node)
end

Memfs.iter_dir = wrappers.err(wrappers.arg_check(iter_dir, "iter_dir", "string"))


function Memfs:rmdir(path)
   local parent_node, err = node.find_parent_dir(self, path)
   if not parent_node then return err end


   local name = path:last()
   local victim_node, err = node.lookup(parent_node, name)
   if err then 
      return errno.ENOTEMPTY
   end

   if victim_node == self.stor.root then
      return errno.EBUSY
   end
    
   -- TODO symlink

   
   err = node.remove_node(self, parent_node, name)
   -- TODO handle times ?
   return err
end


local function create_storage(stor)
   stor.root = node_m.root() 
   stor.cfg = {}
   stor.cfg.page_size = 4096
   return stor
end

function memfs.new(storage, config)
   local fs = {}
   fs._stor = create_storage(storage)
   fs._files = {}
   fs._cfg = config --TODO
   setmetatable(fs, {__index = Memfs})
   return fs
end


return memfs   



