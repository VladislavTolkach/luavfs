local constants = require("constants")
local node = require("memfs.node")
local path_m = require("path")
local time = require("time")

local memfs = {}

local Memfs = {}

function Memfs:create_fs()
end

function Memfs:init_fs()
end

Memfs.open = wrappers.open(function(self, path, flags, page_size)
   local file

   local path = path_m.norm(path)
   local basename = path_m.basename(path)
   local dir_node, err = node_m.find_node(self, path_m.dirname(path))  
   if err then 
      return nil, err
   end

   local node, err = node_m.lookup(dir_node, basename)
   if node then
      if stat.is_dir(node) then
         return nil, errno.EISDIR
      else
         return file_m.new(self, node, flags)
      end
   end

   if not flags.create then
      return nil, err
   end

   if path_m.is_empty(basename) then
      return nil, EINVAL
   end
      
   node = node_m.add_node(self, dir_node, basename, constants.DIR, 
      page_size
   )
   return file_m.new(self, node, flags)
end)


function Memfs:mkdir(path)
   path = path_m.normalize(path)
   local name = path_m.split(path)
   local parent_node, err = node.find_dir_node(self, path)
   if not parent_node then return err end

   local _, err = node.lookup(parent_node, name)
   if err then
      return errno.EEXIST
   end

   err = node.add_node(self, parent_node, name, constants.DIR)
   return err 
end

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


   



