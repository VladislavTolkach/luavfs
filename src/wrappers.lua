local errutils = require("errutils")

local wrappers = {}


function wrappers.arg_check(f, f_name, ...)
   types = arg
   return function(...)
      for i, v in ipairs(types) do
         assert(v == type(arg[i]), 
            errutils.wrong_argtype_msg(types[i], type(arg[i]), i, f_name)
         )
      end
   end
end

function wrappers.err_noret(f)
   return function(...)
      local err = f(...)
      if err then
         return err, errutils.str_error(err)
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
         return nil, err, errutils.str_error(err)
      end
   end
end

function wrappers.open(f)
   return wrappers.err(function(path, mode)
      assert(type(path) == "string", 
         errutils.wrong_argtype_msg("string", type(path), 1, "open")
      )
      assert(type(mode) == "string", 
         errutils.wrong_argtype_msg("string", type(mode), 2, "open")
      )

      local flag = {r, w, trunc, create, append}
      if not mode or mode == "r" then
         flag.r = true
      elseif mode == "r+" then
         flag.r = true
         flag.w = true
      elseif mode == "w" then
         flag.w = true
         flag.trunc = true
         flag.create = true
      elseif mode == "w+" then
         flag.r = true
         flag.w = true
         flag.trunc = true
         flag.create = true
      elseif mode == "a" then
         flag.w = true
         flag.append = true
         flag.create = true
      elseif mode == "a+" then
         flag.r = true
         flag.w = true
         flag.append = true
         flag.create = true
      else
         return nil, errno.EINVAL
      end

      return f(path, flag)
   end)
end

function wrappers.write(f)
   return wrappers.err(function(...)
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
      return f(table.concat(stack))
   end)
end


return wrappers


















