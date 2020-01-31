local fdata_m = {}

local math, string, table = math, string, table

function fdata_m.new(page_size)
   local fdata = {}
   fdata.page_size = page_size
   fdata.page_count = 0
   fdata.last_page = 0
   fdata.size = 0
   fdata.page = {}
   --page_mt(fdata)
   return fdata
end

local null_symbol = "\0"
if FD_DEBUG then null_symbol = "0" end

local function get_null_string(size)
   return string.rep(null_symbol, size)
end

local function find_prev_nonempty_page(fdata, pno)
   for i = (pno - 1), 0, -1 do
      if fdata.page[i] then
         return i 
      end
   end
   return nil
end

function fdata_m.truncate(fdata, length)
   if length == 0 then
      for i = 0, fdata.last_page do
         fdata.page[i] = nil
      end
      fdata.page_count = 0
      fdata.last_page = 0
      fdata.size = 0
      return
   end

   local fd_size = fdata.size
   if length >= fd_size then return end
   local lp = fdata.last_page
   local nlp = math.floor(length / fdata.page_size)
   local page = fdata.page[nlp]
   local poff = length - nlp * fdata.page_size
   if page and poff ~= 0  then 
      fdata.page[nlp] = string.sub(page, 1, poff) ..
                        get_null_string(fdata.page_size - poff)
      fdata.last_page = nlp
      fdata.size = length
   else
      local last_nonempty = find_prev_nonempty_page(fdata, nlp)
      if last_nonempty then 
         fdata.last_page = last_nonempty
         fdata.size = (last_nonempty + 1) * fdata.page_size
      else 
         fdata.last_page = 0
         fdata.size = 0
      end
      nlp = nlp - 1
   end
   
   if nlp ~= lp then  
      for i = (nlp + 1), lp do
         if fdata.page[i] then
            fdata.page[i] = nil
            fdata.page_count = fdata.page_count - 1
         end
      end
   end 
end

local function read_chunk(fdata, pno, startpos, endpos)
   if not fdata.page[pno] then
      local endpos = endpos or fdata.page_size
      return get_null_string(endpos - startpos)
   else
      return string.sub(fdata.page[pno], startpos + 1, endpos)
   end
end

local function read_page(fdata, pno)
   if fdata.page[pno] then
      return fdata.page[pno]
   else
      return get_null_string(fdata.page_size)
   end
end

function fdata_m.read(fdata, offset, length)
   local first_page = math.floor(offset / fdata.page_size) 
   local last_page = math.floor((offset + length) / fdata.page_size)

   local full_page_num = last_page - first_page
   if full_page_num == 0 then
      local poff = offset - first_page * fdata.page_size
      return read_chunk(fdata, first_page, poff, poff + length)  
   end

   local fpoff = offset - first_page * fdata.page_size
   local lpoff = offset + length - last_page * fdata.page_size
   local fpchunk = read_chunk(fdata, first_page, fpoff)
   local lpchunk = read_chunk(fdata, last_page, 0, lpoff)
   if full_page_num == 1 then
      return (fpchunk .. lpchunk)
   else 
      local stack = {fpchunk}
      for pi = first_page + 1, last_page - 1 do
         table.insert(stack, read_page(fdata, pi))
         for i = table.getn(stack) - 1, 1, -1 do
            if string.len(stack[i]) > string.len(stack[i + 1]) then
               break
            end
            stack[i] = stack[i] .. table.remove(stack)
         end
      end
      table.insert(stack, lpchunk)
      return table.concat(stack)
   end
end

local function write_chunk(fdata, pno, startpos, data)
   local data_len = string.len(data)
   if data_len == 0 then return end
   local endpos = startpos + data_len
   local page = fdata.page[pno]
   if page then
      fdata.page[pno] = string.sub(page, 1, startpos) .. data .. 
                        string.sub(page, endpos + 1)
   else
      fdata.page[pno] = get_null_string(startpos) .. data ..
                        get_null_string(fdata.page_size - endpos)
      fdata.page_count = fdata.page_count + 1
   end
end

function fdata_m.write(fdata, offset, data)
   local data_len = string.len(data)
   if data_len == 0 then return data_len end
   local first_page = math.floor(offset / fdata.page_size) 
   local last_page = math.floor((offset + data_len) / fdata.page_size)

   local fpoff = offset - first_page * fdata.page_size
   local lpoff = offset + data_len - last_page * fdata.page_size
   local newsize = fdata.page_size * last_page + lpoff
   if newsize > fdata.size then
      fdata.size = newsize
      if last_page > fdata.last_page then
         if lpoff == 0 then 
            fdata.last_page = last_page - 1
         else
            fdata.last_page = last_page
         end
      end
   end

   local full_page_num = last_page - first_page
   if full_page_num == 0 then
      write_chunk(fdata, first_page, fpoff, data)
   else 
      write_chunk(fdata, first_page, fpoff, 
         string.sub(data, 1, fdata.page_size - fpoff)
      )
      write_chunk(fdata, last_page, 0, string.sub(data, data_len - lpoff + 1))

      if full_page_num ~= 1 then
         local doff = fdata.page_size - fpoff 
         for i = 0, full_page_num - 2 do
            if not fdata.page[first_page + i + 1] then
               fdata.page_count = fdata.page_count + 1
            end
            fdata.page[first_page + i + 1] = string.sub(
               data,
               doff + fdata.page_size * i + 1,
               doff + fdata.page_size * (i + 1)
            )
         end
      end
   end
   
   return data_len
end

return fdata_m


