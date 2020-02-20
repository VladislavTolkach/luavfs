local constants = require("constants")

local stat = {}

function stat.is_dir(mode)
   return (mode == constants.DIR)
end

function stat.is_reg(mode)
   return (mode == constants.REG)
end

return stat
