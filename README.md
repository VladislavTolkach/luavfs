# luavfs
Lua virtual file system

## Introduction
Luavfs is a library that provides a bunch of file systems and common interface for them. Each file system  is represented as an 
object of `Fs` class. Each opened file as an object of `File` class that have the same interface with Lua `file`.

Let's see an example of using `OsFs`:
```lua
local luavfs = require("luavfs")

-- As an example we get the path from the user
local path_from_user = "./project"

-- Create an instance of OsFs and make path_from_user as a root of it
local osfs, err, str_err = luavfs.osfs(path_from_user)

-- Error handling example
local errno = luavfs.errno
if not osfs then
  if err == errno.ENOENT then
    error("Wrong path")
  else
    -- We can also get str_err like this:
    -- local str_err = errno.str_error(err)
    error(str_err) 
  end
end
  
  
-- Print all directories in ./project/lib
local iter, err = osfs:iterdir("/lib")
if iter then
  for entry in iter do
    local st = osfs:stat("/lib/" .. entry)
    if luavfs.stat.is_dir(st.mode) then
      print(entry)
    end
  end
end


-- Create a new file ./project/myfile
local file, err = osfs:open("myfile", "w+")

if file then
  -- Write something
  file:write("test", 123, "567")
  
  -- Close the file
  file:close()
end
```
Here's an example of how we can build a complex file system by using `MountFs`:
```lua
-- In this example we skip error handling
local luavfs = require("luavfs")

local osfs = luavfs.osfs(".")

-- Create an instance of MemFs and init it with an empty storage
local stor = {}
local memfs = luavfs.memfs(stor)

-- MountFs needs a file system that will be its root
local fs = luavfs.mountfs(memfs)

-- Create a directory that will be the mount point
fs:mkdir("os")

-- And mount osfs without flags
fs:mount(osfs, "os", {})
```

