# luavfs
Lua virtual file system
> ***This library is under development and therefore many things may change and work incorrectly***

## Introduction
Luavfs is a library that provides a bunch of [file systems](https://github.com/VladislavTolkach/luavfs#Filesystems) and common interface for them. Each file system  is represented as an 
object of `Fs` class. Each opened file as an object of `File` class that have the same interface with Lua `file`.

Let's see an example of using [`OsFs`](https://github.com/VladislavTolkach/luavfs#Filesystems):
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
Here's an example of how we can build a complex file system by using [`MountFs`](https://github.com/VladislavTolkach/luavfs#Filesystems):
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
The library does not use the concept of a working directory. Instead you should use `opendir(path)` method of `Fs` which creates a new instance of file system that use path as a root:
```lua
local dir = fs:opendir("/os/dir")

-- Use dir like a file system
for entry in dir:iterdir(".") do
   print(entry)
end
```
## Filesystems
- `OsFs`: Provides access to the file system of your operating system. It's a wrapper over `Lua I/O` and `lfs` and therefore it has a similar behavior.

If you initialize it with some *path*, then you will not be able to access your OS file system below the *path*(unless there are symlinks after the *path*):
```lua
local fs = luavfs.osfs("/dir1/dir2")

local file = fs:open("../../file")
-- it's the same with
local file = fs:open("/file")
```
- `MemFs`: In-memory file system that is implemented without third-party libraries and does not even use `Lua I/O` and therefore it can be used when there is no direct access to the OS. 

Also it used *storage* that fully describes the state of file system. *storage* can be serialized using serializers that ignore metatables.

- `MountFs`: Allows you to build a file system from other file systems.

It must be initialized by any file system that will be used like a root file system. You cannot mount another file system in *path* that does not exist in the root file system. 

