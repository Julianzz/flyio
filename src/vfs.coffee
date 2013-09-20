
assert = require("assert")

options =
  root: __dirname

vfs = require("vfs-local")(options)
vfs.env = {}

module.exports = vfs

