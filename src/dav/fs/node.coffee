jsDAV_iNode = require("jsDAV/lib/DAV/iNode").jsDAV_iNode
Exc         = require("jsDAV/lib/DAV/exceptions")
Util        = require("jsDAV/lib/DAV/util")
util        = require("util")

jsDAV_FS_Node = (vfs,path,stat) ->
  @vfs = vfs
  @path = path
  @stat = stat
  return @
  
( ->
  
  this.getName = ->
    return Util.splitPath(this.path)[1]

  this.setName = (name, callback) ->
    parentPath = Util.splitPath(this.path)[0]
    newName    = Util.splitPath(name)[1]

    newPath = parentPath + "/" + newName
    @vfs.rename newPath, {from: @path}, (err) =>
      if (err)
        return callback(err)
      @path = newPath
      callback()

  this._stat = (path, callback) ->
    
    if !callback 
      callback = path
      path = @path
      
      if @stat
        return callback null, @stat
    @vfs.stat path, {}, (err, stat) =>
      if err || !stat 
        return callback( new Exc.jsDAV_Exception_FileNotFound("File at location " 
          + @path + " not found"))
          
      @stat = stat
      callback(null, stat)

  this.getLastModified = (callback) ->
    @_stat (err, stat) ->
      if err
        return callback(err)

      callback(null, stat.mtime)
        
        
  this.exists =  (callback) ->
    @_stat( (err, stat) ->
      return callback(!err && !stat.err) 
    )
).call( jsDAV_FS_Node.prototype = new jsDAV_iNode() )
    

module.exports = 
  jsDAV_FS_Node: jsDAV_FS_Node