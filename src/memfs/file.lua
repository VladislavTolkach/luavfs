local constants = require("constants")
local errno = require("errno")
local fdata = require("fdata")
local time = require("time")

local file_m = {}


local function write(file, data)
   local n = file._node
   local len = fdata.write(n.data, file._pos, data)
   file._pos = file._pos + len
   n.ctime = time()
   n.mtime = time()
   return len
end

local function append(file, data)
   local n = file._node
   local len = fdata.write(n.data, n.data.size, data)
   t = time()
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

local function badf(file, ...)
   return nil, errno.EBADF, errno.str_error(errno.EBADF)
end

local function close(file)
   file._fs._files[file._fd] = nil
   file._node = nil
   file._fs = nil
   file._fd = nil
   file.write = badf
   file.read = badf
   file.seek = badf 
   file.flush = badf
   file.close = badf
   return true
end

function file_m.new(fs, node, flags, page_size)
   local fd = utils.find_free_index(fs._files)
   local file = {}
   fs._files[fd] = file
   file._node = node
   file._fs = fs
   file._fd = fd

   local data = file._node.data
   if flags.trunc then
      fdata.truncate(data, 0)
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
   file.flush = function() end

   -- Close
   file.close = close

   return file
end

return file_m







