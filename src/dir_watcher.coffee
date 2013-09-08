

util = require("util")
FileWatcher = require("./file_watcher")

module.exports = DirWatcher

class DirWatcher extends FileWatcher
  _onChange: (event, path) ->
    self = @
    if not @watcher
      return 
    
    @vfs.stat @path, {} , (err, stat)=>
      exists =  not err and stat and not stat.err
      if not exists
        @emit "delete" , {
          path: @path
        }
      else if event is "rename" 
        @readDir (err,files) ->
          return if err
          @emit "change", {
            path:@path
            files: files
            lastmod: stat.mtime
          }

  readDir: (callback) ->
    @vfs.readdir @path, { encoding: null }, (err,meta) =>
      return callback( err ) if err
      stream = meta.stream
      files = [] 
      stream.on "data", (stat) ->
        files.pash {
          type: if stat.mime is "inode/directory" then "folder" else "file"
          name: stat.name
        }
      called = null
      stream.on "error", (err) ->
        return if called
        called = true
        callback( err )
        
      stream.on "end", ->
        return if called
        called = true
        callback null, files
      