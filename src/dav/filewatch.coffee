jsDAV_ServerPlugin = require("jsDAV/lib/DAV/plugin").jsDAV_ServerPlugin
util               = require("util")
events             = require("events")

class FileWatch extends events.EventEmitter
  constructor: (options) ->
    self = @
    
    @plugin = (handler) ->
      jsDAV_ServerPlugin.call @, handler

      handler.addEventListener "afterWriteContent", (e, uri) ->
        self.emit "afterWrite", { file: "/" + uri }
        e.next()

      handler.addEventListener "afterDelete", (e, uri) ->
        self.emit "afterDelete", { file: "/" + uri }
        e.next()
      
      handler.addEventListener "afterMove", (e, uri)->
        self.emit "afterMove", { file: "/" + uri }
        e.next()
    
      handler.addEventListener "afterCopy", (e, uri)->
        self.emit "afterCopy", { file: "/" + uri }
        e.next()

    util.inherits(@plugin, jsDAV_ServerPlugin) 

  getPlugin: ->
    return @plugin

module.exports = FileWatch
