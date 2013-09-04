
async = require("asyncjs");
_ = require("underscore")
eventbus = require("./eventbus")

class ProcessManager
  
  constructor: (@runners, @eventEmitter)->
    @processes = {}
  
  destroy: ->
    @disposed = true
    @clearInternal( @shutDownInternal )
    ps = @ps()
    _.each( ps, @kill )
    
  prepareShutdown:(callback) =>
    processCount = 0
    
    @shutDownInterval = setInterval (=>
      processCount = _.size( @ps() ) 
      if not processCount
        return callback()
      ), 100 
    
  kill: (pid, callback) ->
    if typeof callback != "function" 
      callback = ->

    child = @processes[pid]
    if !child
      return callback("Process does not exist") 

    child.killed = true
    child.kill("SIGKILL")
    callback()
    
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
    return onStart("cannot run script - the process manager has already been disposed") if @disposed

    runnerFactory = @runners[runnerId]
    return onStart("Could not find runner with ID " + runnerId) if !runnerFactory
    
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
      return callback("cannot run script - the process manager has already been disposed");

    runnerFactory = @runners[runnerId]
    if not runnerFactory
      return callback("Could not find runner with ID " + runnerId) 

    runnerFactory options, @eventEmitter, eventName, (err, child) =>
      return callback(err) if err
      
      child.spawn (err) =>
        return callback(err) if err

        @processes[child.pid] = child 
        callback(null, child.pid, child) 
        @tcpChecker runnerId, child, eventName
        

  tcpChecker: (runnerId, child, eventName) ->
    self = @
    return if _.indexOf( @runnerTypes(), runnerId ) == -1 
    i = 0
    tcpIntervals = [500, 1000, 2000, 4000, 8000]
          
    checkTCP = ->
      
      @exec "shell", { command: "lsof",args: ["-i", ":"+ (child.port || 8080)] }
        ,( (err, pid) ->
        ), (code, stdout, stderr ) ->
          return if (code)
          if stdout 
            msg = 
              "type": runnerId + "-web-start"
              "pid": child.pid
              "url": child.url
            @eventEmitter.emit(eventName, msg)

          else if ++i < tcpIntervals.length 
            setTimeout(checkTCP, tcpIntervals[i])
 
    setTimeout checkTCP, tcpIntervals[i]

runners = {}
eventEmitter = eventbus
pm = new ProcessManager(runners, eventEmitter)

module.exports = 
  
  ProcessManager: ProcessManager
  
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
        
  kill: pm.kill.bind(pm) 
  addRunner: (name, runner) ->
    runners[name] = runner
      
  execCommands: pm.execCommands.bind(pm)
  destroy: pm.destroy.bind(pm)
  prepareShutdown: pm.prepareShutdown.bind(pm)
