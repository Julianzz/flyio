jsDAV_FS_Node     = require("./node").jsDAV_FS_Node
jsDAV_FS_File     = require("./file").jsDAV_FS_File
jsDAV_Directory   = require("jsDAV/lib/DAV/directory").jsDAV_Directory
jsDAV_iCollection = require("jsDAV/lib/DAV/iCollection").jsDAV_iCollection
jsDAV_iQuota      = require("jsDAV/lib/DAV/iQuota").jsDAV_iQuota

Path              = require("path")
Exc               = require("jsDAV/lib/DAV/exceptions")
Stream            = require('stream').Stream


jsDAV_FS_Directory = (vfs, path, stat ) ->
  @vfs = vfs
  @path = path
  @stat = stat
  return @

require("util").inherits(jsDAV_FS_Directory, jsDAV_FS_Node);

( ->

  this.implement(jsDAV_Directory, jsDAV_iCollection, jsDAV_iQuota)
  
  this.createFileStream = (handler, name, enc, callback) ->
    size = handler.httpRequest.headers["x-file-size"]
    if (size) 
      if (!handler.httpRequest.headers["x-file-name"])
        handler.httpRequest.headers["x-file-name"] = name
      @writeFileChunk(handler, enc, callback)
    else 
      newPath = @path + "/" + name
      @vfs.mkfile newPath, {}, (err, meta) =>
        if (err)
          return callback(err)

        handler.getRequestBody(enc, meta.stream, callback)
        
        
  this.writeFileChunk = (handler, type, callback) ->
    size = handler.httpRequest.headers["x-file-size"]
    if !size 
      return callback("Invalid chunked file upload, the X-File-Size header is required.")
      
    filename = handler.httpRequest.headers["x-file-name"]
    path = @path + "/" + filename 

    track = handler.server.chunkedUploads[path] 
    if track
      @upload(track)
    else 
      @vfs.mkfile path, {}, (err, meta) =>
        return callback(err) if err
        
        meta.stream.on "error", (err) ->
          console.error("Stream error:", err)

        track = handler.server.chunkedUploads[path] =
          stream: meta.stream,
          timeout: null,
          length: 0

        @upload(track)

      return

  this.upload = (track)->
    clearTimeout(track.timeout)

    track.timeout = setTimeout () ->
      delete handler.server.chunkedUploads[path]
      track.stream.emit("error", "Upload timed out")
      track.stream.end()
    , 600000 
    
    
    stream = new Stream()
    stream.writable = true

    stream.write = (data) =>
      track.length += data.length
      track.stream.write(data)

    stream.on "error", (err) ->
      track.stream.emit("error", err)

    stream.end = =>
      if track.length == parseInt(size, 10) 
        delete handler.server.chunkedUploads[path]
        track.stream.end()
        handler.dispatchEvent("afterBind", handler.httpRequest.url, @path + "/" + filename)

      @emit("close")

    handler.getRequestBody(type, stream, callback) 


  this.createDirectory = (name, callback) ->
    newPath = @path + "/" + name
    @vfs.mkdir newPath, {}, callback 


  this.getChild = (name, callback) ->
    path = Path.join(@path, name)
    @_stat path, (err, stat) =>
      if err
        return callback(new Exc.jsDAV_Exception_FileNotFound("File at location " + path + " not found"))

      callback null, if stat.mime == "inode/directory" then new jsDAV_FS_Directory(@vfs, path, stat) else new jsDAV_FS_File(@vfs, path, stat)
          

  this.getChildren = (callback) ->
    @vfs.readdir @path, { encoding: null }, (err, meta) =>
      if (err)
        return callback(err)

      stream = meta.stream
      nodes = []

      stream.on "data", (stat) =>
        if stat.mime == 'inode/symlink' and stat.linkStat 
          stat = stat.linkStat
                             
        path = if stat.fullPath then stat.fullPath else Path.join(@path, stat.name)
        
        nodes.push if stat.mime == "inode/directory" then new jsDAV_FS_Directory(@vfs, path, stat) else new jsDAV_FS_File(@vfs, path, stat)


      stream.on "end", ->
        callback(null, nodes)


  this.delete = (callback) ->
    @vfs.rmdir(@path, { recursive: true }, callback)

  this.getQuotaInfo = (callback) ->
    return callback(null, [0, 0])

).call(jsDAV_FS_Directory.prototype )
  

module.exports = 
  jsDAV_FS_Directory: jsDAV_FS_Directory
