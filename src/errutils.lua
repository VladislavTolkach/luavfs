local errutils = {}

function errutils.wrong_arg_msg(func_name, arg_no, msg)
   return "bad argument #"..arg_no.." to '"..func_name.."' ("..msg..")"
            
end

function errutils.wrong_argtype_msg(func_name, arg_no, real_type, expected_type, ...)
   local types = {...}
   if next(types) then
      expected_type = expected_type .. " or " .. table.concat({...}, " or ")
   end
   return   "bad argument #"..arg_no.." to '"..func_name.."' ("..expected_type..
            " expected, got "..real_type..")"
end

function errutils.type_check(func_name, arn_no, var, expected_type) 
   assert(type(var) == expected_type, 
      errutils.wrong_argtype_msg(func_name, arg_no, type(var), expected_type)
   )
end

function errutils.wrong_arg(func_name, arg_no, msg)
   error(errutils.wrong_arg_msg(func_name, arg_no, msg))
end

return errutils

