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

function Memfs:open(path, mode)
   local rw_mode, append, trunc, create
   if not mode or mode == "r" then
      rw_mode = file_m.READ
   elseif mode == "r+" then
      rw_mode = file_m.READ_WRITE
   elseif mode == "w" then
      rw_mode = file_m.WRITE
      trunc = true
      create = true
   elseif mode == "w+" then
      rw_mode = file_m.READ_WRITE
      trunc = true
      create = true
   elseif mode == "a" then
      rw_mode = file_m.WRITE
      append = true
      create = true
   elseif mode == "a+" then
      rw_mode = file_m.READ_WRITE
      append = true
      create = true
   else
      return nil, errno.EINVAL
   end

   -- if the file exists, so returning it
   local file
   local nd, err = namei_m.path_lookup(fs, pathname)
   if nd then
      if nd.last_is_dir then 
         inode_m.put_inode(nd.inode)
         return nil, errno.EISDIR
      end
      file, err = file_m.new_file(fs, nd.inode, rw_mode, append, trunc)
      if not file then
         inode_m.put_inode(nd.inode)
         return nil, err
      end
      return file
   end

   if not create then
      return nil, err
   end

   -- if the file does not exist and "create" flag is set, 
   -- then we are trying to find a directory where the file will be created
   nd, err = namei_m.path_lookup(fs, pathname, true)
   if not nd then
      return nil, err
   end

   -- check that the name of the new file does not match with: "", ".", ".."
   if not nd.last_name then
      inode_m.put_inode(nd.inode)
      return nil, errno.EINVAL
   end

   local inode, err = dir_m.create(nd.inode, nd.last_name, nil)
   inode_m.put_inode(nd.inode)
   if not inode then 
      return nil, err
   end

   file, err = file_m.new_file(fs, inode, rw_mode, append, trunc)
   if not file then
      inode_m.put_inode(inode)
      return nil, err
   end
   return file
end

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


   



