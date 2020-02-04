local time = require("src.time")

local node_m = {}

local function new_node(fs, mode, page_size)
   local node = {}
   node.mode = mode
   node.nlink = 1
   local t = time()
   node.ctime = t
   node.atime = t
   node.mtime = t
   -- node.childs = nil
   -- node.data = nil
   if stat.is_dir(mode) then
      node.childs = {}
   elseif stat.is_reg(mode) then
      local page_size = page_size or fs._cfg.page_size
      node.data = fdata_m.new(page_size)
   elseif stat.is_tbl(mode) then
      node.data = {}
   end
   return node
end

function node_m.add_node(fs, dir_node, name, mode, page_size)
   local node = new_node(fs, mode) 
   dir_node.childs[name] = node
   return node
end

function node_m.remove_node(fs, dir_node, name)
   local victim = dir_node.childs[name] 
   victim.nlink = victim.nlink - 1
   dir_node.childs[name] = nil
end

function node_m.lookup(dir_node, name)
   return dir_node.childs[name]
end

function node_m.find_node(fs, path)
   local node = fs.root_node
   local err
   for name in path:iterate() do
      if not stat.is_dir(node.mode) then
         err = errno.ENOTDIR
         break
      end

      node = node.clilds[name]
      if not node then 
         err = errno.ENOENT
      end
   end

   if err then
      return nil, err
   else
      return node
   end
end

function node_m.find_dir_node(fs, path)
   local node, err = node_m.find_node(fs, path)
   if err then 
      return nil, err
   else
      if not stat.is_dir(node.mode) then
         return nil, errno.ENOTDIR
      else 
         return node
      end
   end
end

return node_m
