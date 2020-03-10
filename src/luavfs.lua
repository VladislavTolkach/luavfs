local luavfs = {}

luavfs.stat = require("stat")
luavfs.errno = require("errno")
luavfs.memfs = require("memfs/fs").new

return luavfs
