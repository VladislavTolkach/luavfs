local utils = {}

function utils.find_free_index(t)
   local found
   local max_index = table.maxn(t)
   for i = 1, max_index do 
      if not t[i] then 
         found = i
         break 
      end 
   end

   if not found then 
      return max_index + 1 
   end

   return found
end


function utils.wrong_arg_msg(msg, arg_no, func_name)
   return "bad argument #"..arg_no.." to '"..func_name.."' ("..msg..")"
            
end

function utils.wrong_argtype_msg(expected_type, real_type, arg_no, func_name)
   return   "bad argument #"..arg_no.." to '"..func_name.."' ("..expected_type..
            " expected, got "..real_type..")"
end

return utils

