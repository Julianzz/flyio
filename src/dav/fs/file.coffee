jsDAV_FS_Node = require("./node").jsDAV_FS_Node
jsDAV_iFile = require("jsDAV/lib/DAV/iFile").jsDAV_iFile
Exc = require("jsDAV/lib/DAV/exceptions")
Util = require("jsDAV/lib/DAV/util")


jsDAV_FS_File = (vfs, path, stat) ->
  @vfs = vfs
  @path = path
  @stat = stat
  return @

require("util").inherits(jsDAV_FS_File, jsDAV_FS_Node)

( ->
  
  this.implement(jsDAV_iFile)
  
  this.putStream = (handler, type, callback) ->
    
    path = @path
  
    size = handler.httpRequest.headers["x-file-size"]
    if size && size != "undefined" 
      parts = Util.splitPath(@path)
      
      if not handler.httpRequest.headers["x-file-name"]
        handler.httpRequest.headers["x-file-name"] = parts[1]
        
      handler.server.tree.getNodeForPath parts[0], (err, parent) =>
        if err
          return callback(err)
        parent.writeFileChunk(handler, type, callback)
    else
      @vfs.mkfile path, {}, (err, meta) =>
        if err
          if (err.code == "EACCES")
            err = new Exc.jsDAV_Exception_Forbidden("Permission denied to write file:" + path)
          return callback(err)

        handler.getRequestBody(type, meta.stream, callback)

  this.getStream = (start, end, callback) ->

    options = {}
    if typeof start == "number" && typeof end == "number"
      options = { start: start, end: end }

    @vfs.readfile @path, options, (err, meta) =>
      if err
        return callback(err)

      stream = meta.stream

      stream.on "data", (data) ->
        callback(null, data);

      stream.on "error", (err) ->
        callback(err);

      stream.on "end", ->

  this.delete = (callback) ->
    @vfs.rmfile(@path, {}, callback)

  this.getSize = (callback) ->
    @_stat (err, stat) ->
      if (err)
        return callback(err)

      callback(null, stat.size)

  this.getETag = (callback) ->
    @_stat (err, stat) ->
      if (err)
        return callback(err)

      callback(null, stat.etag)


  this.getContentType = (callback) ->
    @_stat (err, stat) ->
      if (err)
        return callback(err)

      callback(null, stat.mime)
  
).call(jsDAV_FS_File.prototype )

module.exports = 
  jsDAV_FS_File: jsDAV_FS_File