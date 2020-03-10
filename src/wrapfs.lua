local WrapFs = {}

function WrapFs:access(self, path, mode)
   path = path_m.normalize(path)
   local err = self:_delegate(path):access(path, mode)
   if err then 
      return err, errno.str_error(err)
   end
end

function WrapFs:open = nil
function WrapFs:mkdir = nil
function WrapFs:rmdir = nil
function WrapFs:rename = nil
function WrapFs:utime = nil
function WrapFs:stat = nil
function WrapFs:link = nil
function WrapFs:unlink = nil
function WrapFs:iterdir = nil

return WrapFs
