local node_m = require("memfs.node")

local storage = {}

local default_conf = {
   page_size = 4096,
}

PAGE_SIZE_MIN = 100


function storage.init(stor, conf)
   stor.root = node_m.root() 
   local conf = conf or {}
   local config = {}
   if not conf.page_size or conf.page_size < PAGE_SIZE_MIN then
      config.page_size = default_conf.page_size
   else
      config.page_size = conf.page_size
   end
   stor.conf = config
end

function storage.is_valid(stor)
   return true
end

return storage
