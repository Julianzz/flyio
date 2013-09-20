
coffee    = require "coffee-script"
vfs       = require "./lib/vfs"

nconf = require("nconf").use("memory")
  .argv()
  .env()
  .file({file: __dirname+"/config.json"})
  .defaults
    "port": 7001
    "davprefix": "/davfils/"
    "filerest": "/filerest"

process.on 'uncaughtException', (err) ->
  console.log(err.stack)

Sparrow = require __dirname+"/lib/sparrow"
server = new Sparrow(vfs)
server.listen(nconf.get("port"))
