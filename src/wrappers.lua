local constants = require("constants")
local errno = require("errno")
local errutils = require("errutils")
--local du = require("debugutils")

local wrappers = {}


function wrappers.arg_check(f, f_name, ...)
   local types = {...}
   return function(obj, ...)
      local args = {...}
      for i, v in ipairs(types) do
         errutils.type_check(f_name, i, args[i], v)
      end
      return f(obj, ...)
   end
end

function wrappers.open(f)
   return function(fs, path, mode, ...)
      errutils.type_check("open", 1, path, "string")
      errutils.type_check("open", 2, mode, "string")

      local flags = {r, w, trunc, create, append}
      if not mode or mode == "r" then
         flags.r = true
      elseif mode == "r+" then
         flags.r = true
         flags.w = true
      elseif mode == "w" then
         flags.w = true
         flags.trunc = true
         flags.create = true
      elseif mode == "w+" then
         flags.r = true
         flags.w = true
         flags.trunc = true
         flags.create = true
      elseif mode == "a" then
         flags.w = true
         flags.append = true
         flags.create = true
      elseif mode == "a+" then
         flags.r = true
         flags.w = true
         flags.append = true
         flags.create = true
      else
         return errno.full_error(errno.EINVAL)
      end

      return f(fs, path, flags, ...)
   end
end

function wrappers.write(f)
   return function(file, ...) 
      local stack = {}
      for i, v in ipairs({...}) do
         if type(v) == "string" or type(v) == "number" then
            table.insert(stack, tostring(v))
         else
            error(errutils.wrong_argtype_msg("write", i, type(v), "string", 
               "number"
            ))
         end

         for i = table.getn(stack) - 1, 1, -1 do
            if string.len(stack[i]) > string.len(stack[i + 1]) then
               break
            end
            stack[i] = stack[i] .. table.remove(stack)
         end
      end

      return f(file, table.concat(stack))
   end
end

local read_format_lookup = {
   ["*a"] = constants.READ_ALL,
   ["*l"] = constants.READ_LINE,
   ["*n"] = constants.READ_NUM,
}

function wrappers.read(f)
   return function(file, format)
      local flag = constants.READ_ALL
      local len
      if format then
      elseif type(format) == "number" then
         if format < 0 then 
            error(errutils.wrong_arg_msg("read", 1, "invalid format"))
         end
         flag = constants.READ_CHUNK 
         len = format
      elseif type(format) == "string" then
         flag = read_format_lookup[format]
         if not flag then
            error(errutils.wrong_arg_msg("read", 1, "invalid format"))
         end
      else
         error(errutils.wrong_argtype_msg(
            "read", 1, type(format), "string", "number"
         ))
      end

      return f(file, flag, len)
   end
end

local seek_option_lookup = {
   ["set"] = constants.SEEK_SET,
   ["cur"] = constants.SEEK_CUR,
   ["end"] = constants.SEEK_END,
}

function wrappers.seek(f)
   return function(file, whence, offset)
      if not whence then 
         return f(file, constants.SEEK_CUR, 0)
      end

      local offset = offset or 0
      errutils.type_check("seek", 1, type(whence), "string")
      errutils.type_check("seek", 2, type(offset), "number")

      opt = seek_option_lookup[whence]
      if opt then
         return f(file, opt, offset)
      else
         error(wrong_arg_msg("seek", 1, "invalid option '"..whence.."'"))
      end
   end
end

return wrappers


















