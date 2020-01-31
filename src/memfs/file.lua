local fdata = require("fdata")

local file_m = {}

local File = {}


local function write(file, data)
   local n = file.node
   local len = fdata.write(n.data, file.pos, data)
   file.pos = file.pos + len
   n.ctime = time()
   n.mtime = time()
   return len
end

local function append(file, data)
   local n = file.node
   local len = fdata.write(n.data, n.data.size, data)
   n.ctime = time()
   n.mtime = time()
   return len
end

local function read(file, flag, len)
   local n = file.node
   local ret
   if flag == constants.READ_CHUNK then
      ret = fdata.read(n.data, file.pos, len)
      file.pos = file.pos + string.len(ret)
      -- TODO pos update
   elseif flag == constants.READ_ALL then
      ret = fdata.read(n.data, 0, n.data.size)
      file.pos = n.data.size
   elseif flag == constants.READ_LINE then
      -- TODO
      return nil, errno.EINVAL
   elseif flag == constants.READ_NUM then
      -- TODO
      return nil, errno.EINVAL
   end

   return ret 
end


return file_m
