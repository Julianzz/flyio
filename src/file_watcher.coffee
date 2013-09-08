util        = require "util" 
{ EventEmitter } = require "events"

class FileWatcher extends EventEmitter
  
  constructor:(@vfs, @path) ->
    
  watch: ->
    self = @
    @vfs.watch @path, { file:true, persistent:true } , (err, meta ) =>
      if err 
        return process.nextTick ->
          @emit "close"
      @watcher = meta.watcher;
      @watcher.on "error", ->
        @emit "close"
      @watcher.on "change", @onChange
    
  onChange:(event) =>
    console.log "inside events", event
    self = @
    if not @watcher
      return 
    @vfs.stat @path, {}, (err, stat) =>
      exists = not err and stat and not stat.err
      if not exists
        @emit "delete", {
          path: @path
        }
      else
        @emit "change", {
          path: @path
          lastmod:stat.mtime
        }
  close: ->
    if @watcher
      @watcher.removeAllListeners()
      @watcher.close()
      @emit "close"
    @watcher = null
    
  hasListeners: ->
    return @listeners("delete").length || @listeners(change).length

module.exports = FileWatcher
