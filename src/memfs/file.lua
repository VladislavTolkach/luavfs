local constants = require("constants")
local errno = require("errno")
local fdata = require("fdata")
local time = require("time")
local utils = require("utils")
local wrappers = require("wrappers")

local file_m = {}

local file_methods = {
   write = true,
   read = true,
   seek = true,
   flush = true,
   close = true,
}

--[[
local closed_file_mt = {
   __index = function(k, v)
      if file_methods[k] then 
         return function()
            return errno.full_error(errno.EBADF)
         end
      end
   end,
}
]]

local function write(file, data)
   local n = file._node
   local len = fdata.write(n.data, file._pos, data)
   file._pos = file._pos + len
   local t = time()
   n.ctime = t
   n.mtime = t
   return len
end

local function append(file, data)
   local n = file._node
   local len = fdata.write(n.data, n.data.size, data)
   local t = time()
   n.ctime = t
   n.mtime = t
   return len
end

local function read(file, flag, len)
   local n = file._node
   local ret
   if flag == constants.READ_CHUNK then
      ret = fdata.read(n.data, file._pos, len)
      if ret then 
         file._pos = file._pos + string.len(ret)
      end
   elseif flag == constants.READ_ALL then
      ret = fdata.read(n.data, 0, n.data.size)
      file._pos = n.data.size
   elseif flag == constants.READ_LINE then
      -- TODO
      return nil, errno.EINVAL
   elseif flag == constants.READ_NUM then
      -- TODO
      return nil, errno.EINVAL
   end
   n.atime = t   
   return ret 
end

local function seek(file, opt, offset)
   local pos 
   if opt == constants.SEEK_CUR then
      pos = file._pos
   elseif opt == constants.SEEK_END then
      pos = file._node.data.size
   elseif opt == constants.SEEK_SET then
      pos = 0
   end
   newpos = pos + offset
   if newpos < 0 then
      return nil, errno.EINVAL
   else
      file._pos = newpos
      return newpos
   end
end

local function flush(file, ...)
   return true
end

local function badf(file, ...)
   return errno.full_error(errno.EBADF)
end

local function close(file)
   file._fs._files[file._fd] = nil
   file._node = nil
   file._fs = nil
   file._fd = nil
   --setmetatable(file, closed_file_mt)
   for k, _ in pairs(file_methods) do
      file[k] = badf
   end
   return true
end

function file_m.new(fs, node, flags) 
   local fd = utils.find_free_index(fs._files)
   local file = {}
   fs._files[fd] = file
   file._node = node
   file._fs = fs
   file._fd = fd
   file._pos = 0

   if flags.trunc then
      fdata.truncate(node.data, 0)
   end

   -- Set write func
   if flags.w then
      if flags.append then
         file.write = wrappers.write(append)
      else 
         file.write = wrappers.write(write)
      end
   else
      file.write = badf
   end

   -- Set read func
   if flags.r then
      file.read = wrappers.read(read)
   else
      file.read = badf
   end
   
   -- Seek
   file.seek = wrappers.seek(seek)

   -- TODO Mb add buffers
   -- Flush
   file.flush = flush

   -- Close
   file.close = close

   return file
end

return file_m







