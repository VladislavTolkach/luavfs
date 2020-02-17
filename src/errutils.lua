local errutils = {}

function errutils.wrong_arg_msg(msg, arg_no, func_name)
   return "bad argument #"..arg_no.." to '"..func_name.."' ("..msg..")"
            
end

function errutils.wrong_argtype_msg(expected_type, real_type, arg_no, func_name)
   return   "bad argument #"..arg_no.." to '"..func_name.."' ("..expected_type..
            " expected, got "..real_type..")"
end

return errutils

