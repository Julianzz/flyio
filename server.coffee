
coffee = require("coffee-script");
express = require("express");

nconf = require("nconf").use("memory")
  .argv()
  .env()
  .file({file: __dirname+"/config.json"})
  .defaults
    "PORT": 7001


process.on 'uncaughtException', (err) ->
  console.log(err.stack)

server = require __dirname+"/lib/server"

server.listen(nconf.get("port"))

vfsLocal = require("vfs-local")

vfs = vfsLocal({ root: "/" })
vfs.env = {}

Watcher = require "./lib/file_watcher"
watcher =new Watcher(vfs, __dirname+"/data/zhong.txt")

watcher.watch()

watcher.on "change",(event) ->
  console.log event
  
fs = require "fs"
fs.watch __dirname+ '/data/zhong.txt', { persistent :true }, (event, filename)->
  console.log('event is: ' + event);
