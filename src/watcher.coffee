DirWatcher = require("./dir_watcher")
FileWatcher = require("./file_watcher")
  
#
#watch a serail of files or directories
#
class Watcher
  
  constructor: (vfs) ->
    @watchers = {} 
    @vfs = vfs
  
  # watch path,
  # return WatcherListener
  
  watch: ( path, onChange, onClose, onError ) ->
    
    @vfs.stat path, {}, (err,stat) =>
      return onError(err) if err
      isDir = stat.mime is "inode/directory"
      
      class WatcherListener
        constructor:(watcher,watchers) ->
          @watcher = watcher
          @watchers = watchers
          @watchered = false
          
          @watch()

        watch: ->
          if not @watchered 
            @watcher.on "change", @change
            @watcher.on "delete", @delete
            @watcher.on "close", @close
            @watchered = true
        
        unwatch: ->
          if @watchered
            @watcher.removeListener "change", @_onChange
            @watcher.removeListener "delete", @_onDelete
            @watcher.removeListener "close",  @_onClose
            @watchered = false
            if not @watcher.hasListeners()
              @watcher.close()
              delete @watcher[path]
        
        _onChange: (e) =>
          e.subtype = "remove"
          onChange(e)
        _onDelete: (e) =>
          e.subtype = if isDir then "directorychange" else "change"
          onChange(e)
        _onClose: =>
          delete @watchers[path]
          
      watcher = @watchers[path]
      if not watcher
        watcher = if isDir then new DirWatcher(@vfs,path) else new FileWatcher(@vfs,path)
        watcher.watch()
      
      listener = new WatcherListener( watcher, @watchers )
      reuturn listener
  
  unwatch: (listener) ->
    listener.unwatch()
    
  dispose: ->
    for key ,value of @watchers
      @watchers[key].close()
      delete @watchers[key]
      
vfs = require "./vfs"
_watcher = new Watcher(vfs)

module.exports.Watcher  = Watcher
module.exports.watch    = (path,onChange, onClose, onError ) ->
  return _watcher.watch path,onChange, onClose, onError
module.exports.unwatch  =(listerner) ->
  _watcher.unwatch(listener)

  
  
  