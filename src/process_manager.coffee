
async             = require "asyncjs"
_                 = require "underscore"
{ EventEmitter }  = require "events"

class ProcessManager
  
  constructor: (@runners, @eventEmitter,@processes = {} )->
    
  destroy: ->
    @disposed = true
    @clearInternal( @shutDownInternal )
    processes = @ps()
    _.each( processes, @kill )
    
  prepareShutdown:(callback) =>
    processCount = 0
    
    @shutDownInterval = setInterval =>
      processCount = _.size( @ps() )
      if not processCount
        return callback()
    , 100
    
  kill: (pid, callback) ->
    if typeof callback != "function"
      callback = ->

    child = @processes[pid]
    
    return callback("Process does not exist") if not child

    child.killed = true
    child.kill("SIGKILL")
    callback() if callback?

  debug: (pid, debugMessage, callback) ->
    child = @processes[pid]
    if !child or !child.pid
      return callback("Process is not running: " + pid)

    if !child.debugCommand
      return callback("Process does not support debugging: " + pid)

    child.debugCommand(debugMessage)
    callback()
    
  runnerTypes: ->
    exclude = [
      "npm"
      "shell"
      "run-npm"
      "other"
    ]
    return _.filter _.keys(@runners), (runner) ->
      return exclude.indexOf(runner) == -1
      
  exec: (runnerId, options, onStart, onExit) ->
    self = @
    return onStart("cannot run script - the process"
      " manager has already been disposed") if @disposed

    runnerFactory = @runners[runnerId]
    return onStart("Could not find runner with ID "
      + runnerId) if not runnerFactory
    
    runnerFactory options, @eventEmitter, "", (err, child) =>
      return onStart(err) if err
      child.exec (err, pid) ->
        return onStart(err) if err
        self.processes[child.pid] = child
        onStart null, child.pid
    , onExit
        
  ps: ->
    list = {}
    for pid,child of @processes
      if !child.pid || child.killed
        delete @processes[pid]
      else
        list[pid] = child.describe()
        list[pid].extra = child.extra
    return list

  execCommands: (runnerId, cmds, callback) ->
    out = ""
    err = ""
    async.list(cmds).each (cmd, next) =>
      runner = @exec runnerId, cmd, (err, pid)->
        return next(err) if err
      , (code, stdout, stderr) ->
        out += stdout
        err += stderr
        return next("Error: " + code + " " + stderr, stdout) if (code)
        next()

      runner.end (err)->
        callback(err, out)
      
  
  spawn: (runnerId, options, eventName, callback) ->
    if @disposed
      return callback("cannot run script - the process manager "
        "has already been disposed")

    runnerFactory = @runners[runnerId]
    if not runnerFactory
      return callback("Could not find runner with ID " + runnerId)

    runnerFactory options, @eventEmitter, eventName, (err, child) =>
      return callback(err) if err
      
      child.spawn (err) =>
        return callback(err) if err

        @processes[child.pid] = child
        callback(null, child.pid, child)

   
runners = {}
eventbus = new EventEmitter()
pm = new ProcessManager(runners, eventbus )

module.exports = 

  ProcessManager: ProcessManager
  
  #events management
  on: eventbus.on.bind(eventbus)
  emit: eventbus.emit.bind(eventbus)
  removeAllListeners: eventbus.removeAllListeners.bind(eventbus)
  removeListener: eventbus.removeListener.bind(eventbus)

  ps: (callback) ->
    callback(null, pm.ps())
      
  runnerTypes: (callback) ->
    callback(null, pm.runnerTypes())
      
  debug: pm.debug.bind(pm)
  spawn: pm.spawn.bind(pm)
  
  exec: (runnerId, options, callback) ->
    pm.exec runnerId, options, (err, pid) ->
      return callback(err) if (err)
    , callback
        
  kill: (pid, callback)->
    pm.kill pid,callback
  
  addRunner: (name, runner) ->
    runners[name] = runner
      
  execCommands: pm.execCommands.bind(pm)
  
  destroy: pm.destroy.bind(pm)
  
  prepareShutdown: (callback)->
    pm.prepareShutdown(callback)
