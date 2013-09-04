
assert = require("assert")

options = 
  root: "/"
  
vfs = require("vfs-local")(options)

module.exports = vfs
  