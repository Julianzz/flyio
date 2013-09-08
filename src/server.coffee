Fs            = require 'fs'
OptParse      = require 'optparse'
Path          = require 'path'
App           = require 'express.io'
Vfs           = require './vfs'
logger        = require './log'
httpAdapter   = require 'vfs-http-adapter'
Users         = require './users'

pm            = require './process_manager'
watcher       = require './watcher'

{ EventEmitter } = require 'events'


class Sparrow
  
  constructor: ( @vfs = Vfs, @plugins = [ __dirname + '/plugins' ] )->
    @logger   = logger

    @app      = pm
  
    @users    = Users
    @app.http().io()
    @events   = new EventEmitter
    @pm = pm.ProcessManager()    
    @fileRestPath = "/files"
    @watcher = new watcher.Watcher(@vfs)
    
    loadPlugins( @plugins )
    setupExpress()
    setupVfs()
    setupSocketIO()
  
  #load plugins 
  loadPlugins: (plugins)->
    for fileName in plugins
      load( fileName )
    
  # setup express
  setupExpress: ->
    @app.set('view engine', 'jade')
    @app.set('views', Path.join(__dirname,'../views'))
    @app.get '/', (req, res) ->
      res.sendfile( Path.join(__dirname, '/../views/index.html') )
     
  setupVfs: ->
    restful = httpAdapter( @fileRestPath, @vfs)
    @app.use restful
    
  setupSocketIO: ->
    @app.io.sockets.on 'connection', (socket) ->
      user = @users.addUser(@)
      socket.emit "welcome", user
      socket.on 'disconnect', ->
        @users.removeUser(user)
      
  onEvent: ( eventName, callback) ->
    
  load: (path) ->
    @logger.debug "Loading scripts from #{path}"
    Fs.exists path, (exists) =>
      if exists
        for file in Fs.readdirSync(path)
          @loadFile path, file
          
  # Returns nothing.
  loadFile: (path, file) ->
    ext  = Path.extname file
    full = Path.join path, Path.basename(file, ext)
    if ext is '.coffee' or ext is '.js'
      try
        require(full)(@)
      catch error
        @logger.error "Unable to load #{full}: #{error.stack}"
        process.exit(1)
            
  #wrapper eventemitter 
  on: (event, args...) ->
    @events.on event, args...
  
  emit: (event, args...) ->
    @events.emit event, args...