jsDAV_Tree = require("jsDAV/lib/DAV/tree").jsDAV_Tree
jsDAV_FS_Directory = require("./directory").jsDAV_FS_Directory
jsDAV_FS_File = require("./file").jsDAV_FS_File

Exc = require("jsDAV/lib/DAV/exceptions")
Path = require("path")
Util = require("util")

class jsDAV_Tree_Filesystem extends jsDAV_Tree
  
  constructor: (vfs, basePath)->
    @vfs = vfs
    @basePath = basePath || ""

  getNodeForPath: (path, callback) ->
    
    path = @getRealPath(path)
    nicePath = @stripSandbox(path)
    
    if not @insideSandbox(path) 
      return callback(new Exc.jsDAV_Exception_Forbidden("You are not allowed to access " + nicePath))
      
    @vfs.stat path, {}, (err, stat) =>
      if err
        return callback(new Exc.jsDAV_Exception_FileNotFound("File at location " + path + " not found"))
      node = if stat.mime == "inode/directory" 
      then new jsDAV_FS_Directory( @vfs, path, stat) 
      else new jsDAV_FS_File(@vfs, path, stat)
      
      callback null, node 

  
  getRealPath: (publicPath) ->
    if publicPath.indexOf(this.basePath) == 0
      return publicPath
      
    return Path.join(this.basePath, publicPath) 


  copy = (source, destination, callback) ->

    source = @getRealPath(source)
    destination = @getRealPath(destination)
    
    if not @insideSandbox(destination) 
      return callback(new Exc.jsDAV_Exception_Forbidden( "You are not allowed to copy to " 
        + @stripSandbox(destination)))
    
    self = @
    @vfs.stat source, {}, (err, stat) =>
      if err || stat.err
        return callback(err)
        
      self.vfs.rmdir destination, { recursive: true }, (err) ->
        self.vfs.execFile("cp", {args: ["-R", source, destination]}, callback)

  move: (source, destination, callback) ->
    source = @getRealPath(source)
    destination = @getRealPath(destination)
    if not @insideSandbox(destination) 
      return callback(new Exc.jsDAV_Exception_Forbidden("You are not allowed to move to " + @stripSandbox(destination)))

    @vfs.rename(destination, {from: source}, callback) 

module.exports = 
  jsDAV_Tree_Filesystem: jsDAV_Tree_Filesystem
