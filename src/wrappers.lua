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
         assert(v == type(args[i]), 
            errutils.wrong_argtype_msg(types[i], type(args[i]), i, f_name)
         )
      end
      return f(obj, ...)
   end
end

function wrappers.err_noret(f)
   return function(...)
      local err = f(...)
      if err then
         return err, errno.str_error(err)
      else
         return errno.OK
      end
   end
end

function wrappers.err(f)
   return function(...)
      local ret, err = f(...)
      if ret then
         return ret 
      else
         if err then
            return nil, err, errno.str_error(err)
         else
            return nil
         end
      end
   end
end

function wrappers.open(f)
   return wrappers.err(function(fs, path, mode, ...)
      assert(type(path) == "string", 
         errutils.wrong_argtype_msg("string", type(path), 1, "open")
      )
      assert(type(mode) == "string", 
         errutils.wrong_argtype_msg("string", type(mode), 2, "open")
      )

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
         return nil, errno.EINVAL
      end

      return f(fs, path, flags, ...)
   end)
end

function wrappers.write(f)
   return wrappers.err(function(file, data) 
      local stack = {}
      for i, v in ipairs(arg) do
         if type(v) == "string" or type(v) == "number" then
            table.insert(stack, tostring(v))
         else
            error(errutils.wrong_argtype_msg("string", type(v), i, "write"))
         end

         for i = table.getn(stack) - 1, 1, -1 do
            if string.len(stack[i]) > string.len(stack[i + 1]) then
               break
            end
            stack[i] = stack[i] .. table.remove(stack)
         end
      end

      return f(file, table.concat(stack))
   end)
end

local read_format_lookup = {
   ["*a"] = constants.READ_ALL,
   ["*l"] = constants.READ_LINE,
   ["*n"] = constants.READ_NUM,
}

function wrappers.read(f)
   return wrappers.err(function(file, format)
      local flag = constants.READ_ALL
      local len
      if format then
      elseif type(format) == "number" then
         if format < 0 then 
            error(errutils.wrong_arg_msg("invalid format", 1, "read"))
         end
         flag = constants.READ_CHUNK 
         len = format
      elseif type(format) == "string" then
         flag = read_format_lookup[format]
         if not flag then
            error(errutils.wrong_arg_msg("invalid format", 1, "read"))
         end
      else
         error(errutils.wrong_argtype_msg(
            "string or number", type(format), 1, "read")
         )
      end

      return f(file, flag, len)
   end)
end

local seek_option_lookup = {
   ["set"] = constants.SEEK_SET,
   ["cur"] = constants.SEEK_CUR,
   ["end"] = constants.SEEK_END,
}

function wrappers.seek(f)
   return wrappers.err(function(file, whence, offset)
      if not whence then 
         return f(file, constants.SEEK_CUR, 0)
      end

      local offset = offset or 0
      assert(type(whence) == "string", 
         errutils.wrong_argtype_msg("string", type(whence), 1, "seek"))
      assert(type(offset) == "number", 
         errutils.wrong_argtype_msg("number", type(offset), 2, "seek"))

      opt = seek_option_lookup[whence]
      if opt then
         return f(file, opt, offset)
      else
         error(wrong_arg_msg("invalid option '"..whence.."'", 1, "seek"))
      end
   end)
end

return wrappers


















