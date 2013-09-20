assert = require("assert");
netutil = require("netutil");

options = 
  projectDir: "/Users/lzz/Sparrow/flyio"
  workspaceId: "11"
  host: "0.0.0.0"
  userDir: "/"
  
module.exports = 
  projectDir: options.projectDir
  workspaceId: options.workspaceId
  host: options.host
  userDir: options.userDir
  
  getProjectDir: (callback) ->
    if callback
      callback(null, options.projectDir) 
    else
      return options.projectDir
      
  getWorkspaceId: (callback) ->
    if callback
      callback(null, options.workspaceId)
    else 
      return options.workspaceId
      
  getUnixId: (callback) ->
    if callback
      callback(null, options.unixId || null) 
    else 
      return options.unixId || null
      
  getPort: (callback) ->
    netutil.findFreePort 20000, 64000, options.host, (err, port) ->
      callback(err, port)
      
  getHost: (callback) ->
    if callback
      callback(null, options.host)
    else
      return options.host
      
  getUserDir: (callback) ->
    if callback
      callback(null, options.userDir)
    else
      return  options.userDir

