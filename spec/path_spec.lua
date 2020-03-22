local path = require("src.path")

describe("path", function()
   describe("path.normalize", function()
      it("returns the same if already normalized", function()
         assert.are.same("/", path.normalize("/"))
         assert.are.same("/test", path.normalize("/test"))
         assert.are.same("/test1/test2/", path.normalize("/test1/test2/"))
      end)

      it("returns / if empty", function()
         assert.are.same("/", path.normalize(""))
      end)

      it("converts to abolute if relative", function()
         assert.are.same("/test", path.normalize("/test"))
         assert.are.same("/test", path.normalize("test"))
      end)

      it("keeps the last /", function()
         assert.are.same("/test/", path.normalize("/test/"))
         assert.are.same("/test", path.normalize("/test"))
      end)

      it("ignores .. for root", function()
         assert.are.same("/", path.normalize("/.."))
         assert.are.same("/", path.normalize("/../../../"))
      end)

      it("adds / if ends with . or ..", function()
         assert.are.same("/test/", path.normalize("/test/test/.."))
         assert.are.same("/test/", path.normalize("/test/."))
      end)

      it("removes . and trailing slashes", function()
         assert.are.same("/", path.normalize("///////"))
         assert.are.same("/test/test/test", path.normalize("////test////test//test"))
         assert.are.same("/", path.normalize("./././."))
         assert.are.same("/", path.normalize("././././"))
         assert.are.same("/test/test", path.normalize("///.//./test/.///test"))
      end)

      it("complex samples", function()
         assert.are.same("/test2/", path.normalize(".././test1/../test2/./"))
         assert.are.same("/test1/", path.normalize("/test1/test2/test3/../.."))
         assert.are.same("/test2", path.normalize("/test1/../../../test2"))
      end)
   end)

   local root = "/"
   local reg1 = "/test"
   local reg2 = "/test1/test2/test3"
   local dir1 = "/test/"
   local dir2 = "/test1/test2/test3/"

   describe("path.is_same", function()
      it("returns true if the same", function()
         assert.is_true(path.is_same(root, root))
         assert.is_true(path.is_same(reg2, reg2))
         assert.is_true(path.is_same(dir2, dir2))

         assert.falsy(path.is_same(root, dir1))
         assert.falsy(path.is_same(dir2, reg2))
         assert.falsy(path.is_same(reg1, reg2))
         assert.falsy(path.is_same(dir1, dir2))
      end)
   end)

   describe("path.is_empty", function()
      it("returns true if nil or ''", function()
         assert.is_true(path.is_empty(""))
         assert.is_true(path.is_empty())
         
         assert.falsy(path.is_empty(root))
         assert.falsy(path.is_empty(reg1))
         assert.falsy(path.is_empty(dir1))
      end)
   end)

   describe("path.is_valid", function()
      it("returns true if the path does not contain " .. [[\n]], function()
         assert.is_true(path.is_valid(root))
         assert.is_true(path.is_valid(reg2))
         assert.is_true(path.is_valid(dir2))
         
         assert.falsy(path.is_valid("/test1/\ntest2"))
         assert.falsy(path.is_valid("/test1/\n\n\n\n"))
         assert.falsy(path.is_valid("\n"))
      end)
   end)

   describe("path.is_dir", function()
      it("returns true if ends with /", function()
         assert.is_true(path.is_dir(root))
         assert.is_true(path.is_dir(dir1))
         assert.is_true(path.is_dir(dir2))

         assert.falsy(path.is_dir(reg1))
         assert.falsy(path.is_dir(reg2))
      end)
   end)

   describe("path.is_root", function()
      it("returns true if /", function()
         assert.is_true(path.is_root(root))

         assert.falsy(path.is_root(dir1))
         assert.falsy(path.is_root(reg1))
      end)
   end)

   describe("path.iterate", function()
      it("iter returns nil if /", function()
         local iter = path.iterate(root)
         assert.is_nil(iter())
      end)

      it("iterate " .. dir1, function()
         local iter = path.iterate(dir1)
         assert.are.same("test", iter())
         assert.is_nil(iter())
      end)

      it("iterate " .. reg2, function()
         local iter = path.iterate(dir2)
         assert.are.same("test1", iter())
         assert.are.same("test2", iter())
         assert.are.same("test3", iter())
         assert.is_nil(iter())
      end)
   end)

   describe("path.dir", function()
      it("returns the same if already ends with /", function()
         assert.are.same(root, path.dir(root))
         assert.are.same(dir1, path.dir(dir1))
         assert.are.same(dir2, path.dir(dir2))
      end)

      it("adds / to the end", function()
         assert.are.same(dir1, path.dir(reg1))
         assert.are.same(dir2, path.dir(reg2))
      end)
   end)

   describe("path.undir", function()
      it("returns the same for /", function()
         assert.are.same(root, path.undir(root))
      end)
      it("returns the same if already ends with non-/ char", function()
         assert.are.same(reg1, path.undir(reg1))
         assert.are.same(reg2, path.undir(reg2))
      end)

      it("removes / at the end", function()
         assert.are.same(reg1, path.undir(dir1))
         assert.are.same(reg2, path.undir(dir2))
      end)
   end)

   describe("path.basename", function()
      it("returns nil if ends with /", function()
         assert.is_nil(path.basename(root))
         assert.is_nil(path.basename(dir1))
         assert.is_nil(path.basename(dir2))
      end)

      it("returns last entry", function()
         assert.are.same("test", path.basename(reg1))
         assert.are.same("test3", path.basename(reg2))
      end)
   end)

   describe("path.dirname", function()
      it("returns the same if ends with /", function()
         assert.are.same(root, path.dirname(root))
         assert.are.same(dir1, path.dirname(dir1))
         assert.are.same(dir2, path.dirname(dir2))
      end)

      it("returns the dirname", function()
         assert.are.same("/", path.dirname(reg1))
         assert.are.same("/test1/test2/", path.dirname(reg2))
      end)
   end)

   describe("path.split", function()
      it("returns (/, nil) for /", function()
         local dirname, basename = path.split(root)
         assert.are.same(root, dirname)
         assert.is_nil(basename)
      end)

      it("returns (/.../, name) for /.../name/ or /.../name", function()
         local dirname, basename = path.split(reg1)
         assert.are.same(root, dirname)
         assert.are.same("test", basename)

         local dirname, basename = path.split(dir1)
         assert.are.same(root, dirname)
         assert.are.same("test", basename)

         local dirname, basename = path.split(reg2)
         assert.are.same("/test1/test2/", dirname)
         assert.are.same("test3", basename)

         local dirname, basename = path.split(dir2)
         assert.are.same("/test1/test2/", dirname)
         assert.are.same("test3", basename)
      end)
   end)

   describe("path.frombase", function()
      it("returns nil if the path does not contain the base", function()
         assert.is_nil(path.frombase(dir1, dir2))
         assert.is_nil(path.frombase("/lsjf/d", dir2))
      end)

      it("returns / if base and path are the same", function()
         assert.are.same(root, path.frombase(reg1, reg1))
         assert.are.same(root, path.frombase(dir2, dir2))
      end)

      it("returns the path if base is /", function()
         assert.are.same(reg1, path.frombase(root, reg1))
         assert.are.same(dir2, path.frombase(root, dir2))
      end)

      it("returns the path with excluded base", function()
         assert.are.same("/test2/test3", path.frombase("/test1", reg2))
         assert.are.same("/test2/test3/", path.frombase("/test1", dir2))
         assert.are.same("/test3", path.frombase("/test1/test2", reg2))
      end)
   end)
end)




