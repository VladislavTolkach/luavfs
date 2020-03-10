local errno = {
   ENOENT         = 2,
   EIO            = 5,
   EBADF          = 9,
   EBUSY          = 16,
   EEXIST         = 17,
   ENOTDIR        = 20,
   EISDIR         = 21,
   EINVAL         = 22,
   EMFILE         = 24,
   EFBIG          = 27,
   ENOSPC         = 28,
   ENAMETOOLONG   = 36,
   ENOSYS         = 38,
   ENOTEMPTY      = 39,
}

local string_error = {
   [errno.ENOENT]       = "No such file or directory",
   [errno.EIO]          = "I/O error",
   [errno.EBADF]        = "Bad file number",
   [errno.EBUSY]        = "Device or resource busy",
   [errno.EEXIST]       = "File exists",
   [errno.ENOTDIR]      = "Not a directory",
   [errno.EISDIR]       = "Is a directory",
   [errno.EINVAL]       = "Invalid argument",
   [errno.EMFILE]       = "Too many open files",
   [errno.EFBIG]        = "File too large",
   [errno.ENOSPC]       = "No space left on device", 
   [errno.ENAMETOOLONG] = "File name too long",
   [errno.ENOSYS]       = "Function not implemented",
   [errno.ENOTEMPTY]    = "Directory not empty",
}

function errno.str_error(err_code)
   return string_error[err_code]
end

function errno.full_error(err_code)
   return err_code, string_error[err_code]
end

return errno
