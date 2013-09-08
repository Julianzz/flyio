
coffee = require("coffee-script");
express = require("express");

nconf = require("nconf").use("memory")
  .argv()
  .env()
  .file({file: __dirname+"/config.json"})
  .defaults
    "PORT": 7001
  
server = require __dirname+"/lib/server"

server.listen(nconf.get("port"))


checker = require "./lib/tcp_checker" 

checker.tcpChecker 3000

