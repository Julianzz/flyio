assert          = require("assert")
path            = require("path")
utils           = require("connect").utils
error           = require("http-error")
util            = require('util')

jsDAV            = require("jsDAV")

jsDAV_Tree_Filesystem = require("./fs/tree").jsDAV_Tree_Filesystem
BrowserPlugin         = require("jsDAV/lib/DAV/plugins/browser")
DavFilewatch          = require("./filewatch")
DavPermission         = require("./permission")

class FileSystem
  
  constructor: (sandbox, options ) ->
    
    mountDir = path.normalize(sandbox.projectDir);
    davOptions = 
      path: mountDir
      mount: options.urlPrefix
      plugins: options.davPlugins
      server: {}
      standalone: false


    davOptions.tree = new jsDAV_Tree_Filesystem(options.vfs, mountDir)
    @filewatch = new DavFilewatch()

    @davServer = jsDAV.mount(davOptions)
    
    @davServer.plugins["filewatch"] = @filewatch.getPlugin()
    @davServer.plugins["browser"] = BrowserPlugin
    @davServer.plugins["permission"] = DavPermission
    
  onDestroy: ->
    @davServer.unmount()
  
  run:(req,res)->
    @davServer.exec(req, res);
    
  davServer: ->
    @davServer 
  
  fs: ->
    return {
      on: @filewatch.on.bind(@filewatch)
      addListener: @filewatch.on.bind(@filewatch)
      removeListener: @filewatch.removeListener.bind(@filewatch)
    }
      
  codesearch: {}
  filesearch: {}    

module.exports =  FileSystem