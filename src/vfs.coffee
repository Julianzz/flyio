
assert = require("assert")

options =
  root: "/"

vfs = require("vfs-local")(options)
vfs.env = {}

module.exports = vfs

