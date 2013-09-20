nodefs      = require "vfs-nodefs-adapter"
pm          = require "../process_manager"
utils       = require "../utils"
vfs         = require "../vfs"

class Runner
  name :  "shell" 
  constructor: (vfs, options, callback) ->
    @vfs = vfs
    @fs = nodefs(vfs)
    @uid = options.uid
    @command = options.command
    @args = options.args || []
    @url = options.url 
    @extra = options.extra
    @encoding = options.encoding

    @runOptions = {}
    @runOptions.cwd = options.cwd if options.cwd

    if @encoding 
      @runOptions.stdoutEncoding = @encoding
      @runOptions.stderrEncoding = @encoding

 
    @runOptions.env = options.env if options.env

    @runOptions.env = @runOptions.env || {} 
    @runOptions.env.IP = (vfs.env && vfs.env.OPENSHIFT_DIY_IP) || "0.0.0.0"

    @eventEmitter = options.eventEmitter 
    @eventName = options.eventName 

    @pid = 0

    callback(null, this) 
  
  exec: (onStart, onExit) ->
     self = this
   
     @createChild (err, child) ->

       return onStart(err) if err

       self.child = child
       self.pid = child.pid

       onStart(null, child.pid)

       out = ""
       err = ""

       child.on "exit", (code) ->
         onExit(code, out, err)
         self.pid = 0

       child.stdout.on "data", (data) ->
         out += data.toString("utf8")

       child.stderr.on "data", (data) ->
         err += data.toString("utf8") 

  createChild: (callback) ->
    @runOptions.args = this.args;
    @vfs.spawn @command, @runOptions,(err, meta) ->
      callback(err, meta and meta.process) 

  spawn: (callback) ->
    self = this
    @createChild (err, child) ->
      return callback(err) if (err)
      self.child = child
      self.pid = child.pid

      self.attachEvents(child)

      callback(null, child.pid)

  kill: (signal) ->
    this.child && this.child.kill(signal);

  describe:  ->
    return {
      command: [@command].concat(@args).join(" ")
      type: @name
    }

  attachEvents: (child) ->
    self = @
    pid = child.pid

    emit = (msg) =>
      @eventEmitter.emit(@eventName, msg)

    sender = (stream) ->
      return (data) ->
        emit
          "type": self.name + "-data"
          "pid": pid
          "stream": stream
          "data": data
          "extra": self.extra
        
    child.stdout.on("data", sender("stdout")) 
    child.stderr.on("data", sender("stderr"))
  
    child.on "exit", (code) ->
      self.pid = 0
      emit
        "type": self.name + "-exit"
        "pid": pid
        "code": code || 0
        "extra": self.extra

    process.nextTick ->
      emit
        "type": self.name + "-start"
        "pid": pid
        "extra": self.extra
        
factory = (vfs) ->
  return (args, eventEmitter, eventName, callback) ->
    options = {}

    utils.extend(options, args)
    options.eventEmitter = eventEmitter
    options.eventName = eventName
    options.args = args.args

    return new Runner(vfs, options, callback)
    
module.exports = (app) ->
  
  pm.addRunner "shell", factory(app.vfs) 
  
  return {
    factory: factory
    Runner : Runner
  }


