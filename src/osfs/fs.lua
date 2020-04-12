local utils = require("utils")

local OSFs = {}

function OSFs:access(path, mode)
end

function OSFs:open(path, mode, ...)
end

function OSFs:mkdir(path)
end

function OSFs:rmdir(path)
end

function OSFs:rename(old_path, new_path)
end

function OSFs:utime(path, atime, mtime)
end

function OSFs:stat(path)
end

function OSFs:link(old_path, new_path)
end

function OSFs:unlink(path)
end

function OSFs:iterdir(path)
end

function OSFs:opendir(path)
end

function OSFs.new(path)
end

utils.make_callable(OSFs, OSFs.new)

return OSFs
