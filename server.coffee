
coffee    = require "coffee-script"
express   = require "express" 
vfs       = require "./lib/vfs"

nconf = require("nconf").use("memory")
  .argv()
  .env()
  .file({file: __dirname+"/config.json"})
  .defaults
    "PORT": 7001

process.on 'uncaughtException', (err) ->
  console.log(err.stack)

Sparrow = require __dirname+"/lib/sparrow"
server = new Sparrow(vfs)
server.listen(nconf.get("port"))
