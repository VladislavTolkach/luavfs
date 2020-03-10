local constants = require("constants")
local errno = require("errno")
local stat = require("stat")
local time = require("time")
local fdata_m = require("fdata")
local path_m = require("path")

local node_m = {}

local function new_node(mode, page_size)
   local node = {}
   node.mode = mode
   node.nlink = 1 
   local t = time()
   node.ctime = t
   node.atime = t
   node.mtime = t
   if stat.is_dir(mode) then
      node.childs = {}
   elseif stat.is_reg(mode) then
      node.data = fdata_m.new(page_size)
   end
   return node
end

function node_m.root()
   return new_node(constants.DIR)
end

function node_m.add_node(stor, dir_node, name, mode, page_size)
   local page_size = page_size or stor.cfg.page_size
   local node = new_node(mode, page_size) 
   dir_node.childs[name] = node
   return node
end

function node_m.remove_node(dir_node, name)
   local victim = dir_node.childs[name] 
   victim.nlink = victim.nlink - 1
   dir_node.childs[name] = nil
end

function node_m.lookup(dir_node, name)
   local node = dir_node.childs[name]
   if node then 
      return node
   else
      return nil, errno.ENOENT
   end
end

function node_m.iterate_names(dir_node)
   local t = dir_node.childs
   local i
   return function()
      i = next(t, i)
      return i
   end
end

function node_m.is_empty(dir_node)
   return next(dir_node.childs)
end

function node_m.find_node(stor, path)
   local node = stor.root
   if path_m.is_root(path) then
      return node
   end

   local err
   for name in path_m.iterate(path) do
      if not stat.is_dir(node.mode) then
         err = errno.ENOTDIR
         break
      end

      node = node_m.lookup(node, name)
      if not node then 
         err = errno.ENOENT
         break
      end
   end

   if err then
      return nil, err
   else
      return node
   end
end

return node_m
