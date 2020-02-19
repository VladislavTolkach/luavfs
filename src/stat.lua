local constants = require("constants")

local stat = {}

function stat.is_dir(mode)
   return (mode == constants.DIR)
end

return stat
