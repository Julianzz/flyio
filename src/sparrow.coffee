Fs            = require 'fs'
OptParse      = require 'optparse'
Path          = require 'path'
App           = require 'express.io'
Express       = require 'express'
Vfs           = require './vfs'
Logger        = require './log'
Users         = require './users'
Loader        = require './loader'

nconf         = require("nconf")

DavFileSystem = require "./dav/file_system"

pm            = require './process_manager'
watcher       = require './watcher/watcher'
sandbox       = require "./sandbox"


{ EventEmitter } = require 'events'

class Sparrow
  
  constructor: ( @vfs = Vfs, @pluginsDir = [ __dirname + '/plugins' ], @conf = nconf )->
    @logger   = Logger
    @users    = Users
    @plugins = [] 
    @fileRestPath = "/files"
    @sandbox  = sandbox
    
    @events   = new EventEmitter
    @watcher = new watcher.Watcher(@vfs)
    
    @pm = pm.ProcessManager() 
    
    @app      = App()
    @app.http().io()
    @loadPlugins( @pluginsDir )
    @setupExpress()
    @setupSocketIO()
    
    @loadMiddleware()

    console.log( @app.routes )
    
    
  #load plugins 
  loadPlugins: (plugins)->
    for dirName in plugins
      loader = new Loader(dirName,@)
      loader.loads() 
      [].push.apply( @plugins,loader.plugins )
    console.log @plugins
    
  # setup express
  setupExpress: ->
    @app.set 'view engine', 'jade'
    @app.set 'views', Path.join(__dirname,'../views')
    
    @app.get '/show/:filename',( req, res ) ->
      fullPath = Path.join(__dirname,"..","views" ,req.params.filename )
      res.sendfile( fullPath)
      
    @app.get '/', (req, res) ->
      res.sendfile( Path.join(__dirname, '/../views/index.html') )
      
    @app.use "/static", Express.static( Path.join(__dirname,"..",'media') )
    @app.use(Express.logger())
      
  setupSocketIO: ->
    @app.io.sockets.on 'connection', (socket) =>
      user = @users.addUser(@)      
      socket.emit "welcome", {
        "name": user.name
      }
      socket.on 'disconnect', =>
        @users.removeUser(user)
  
  loadMiddleware: ->
    loader = new Loader(__dirname + '/middleware', @ )
    loader.loads()
    for plugin in loader.plugins
      @app.use plugin
    
  onEvent: ( eventName, callback) ->
                
  #wrapper eventemitter 
  on: (event, args...) ->
    @events.on event, args...
  
  emit: (event, args...) ->
    @events.emit event, args...
    
  listen: (port = 7001, host="0.0.0.0" ) ->
    @logger.info "begin to start server %s:%d", host, port 
    @app.listen(port,host)

module.exports = Sparrow  