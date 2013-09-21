Fs            = require 'fs'
OptParse      = require 'optparse'
Path          = require 'path'
App           = require 'express.io'
Express       = require 'express'

util          = require 'util'
nconf         = require("nconf")

Vfs           = require './vfs'
Users         = require './users'
Loader        = require './loader'

logger        = require './log'

pm            = require './process_manager'
watcher       = require './watcher/watcher'
sandbox       = require './sandbox'

#Robot         = require 'hubot/robot'
robot         = require './robot'

{ EventEmitter } = require 'events'

class Sparrow
  
  constructor: ( @vfs = Vfs, @pluginPaths = [ __dirname + '/plugins' ], @conf = nconf )->
        
    @logger   = logger
    @users    = Users
    @plugins = [] 
    @middlewares = []
    
    @fileRestPath = "/files"
    @middlewarePath = __dirname + "/middleware"
    
    @sandbox  = sandbox
    
    @events  = new EventEmitter
    @watcher = new watcher.Watcher(@vfs)
    
    @pm = pm.ProcessManager() 
    
    @app      = App()
    @app.http().io()
    @setupExpress()
    @setupSocketIO()
    
    @loadPlugins @plugins, @pluginPaths 
    @loadPlugins @middlewares, @middlewarePath, (plugin) =>
      @app.use plugin
        
    @robot = robot.use(@)
    
    #@logger.info( "routes info : ", @app.routes )
         
  #wrapper eventemitter 
  on: (event, args...) ->
    @events.on event, args...
  
  emit: (event, args...) ->
    @events.emit event, args...
    
  listen: (port = 7001, host="0.0.0.0" ) ->
    @logger.info "begin to start server #{host}:#{port}"
    @app.listen(port,host)
         
  onEvent: ( eventName, callback) ->
  
  post: (urlPrefix,callback ) ->
    @app.post urlPrefix, (args...) =>
      callback(args...)
      
  # setup express
  setupExpress: ->
    @app.use(Express.logger())
    @app.use(Express.bodyParser())
    @app.use(require('connect-requestid'))
    
    @app.set 'view engine', 'jade'
    @app.set 'views', Path.join(__dirname,'../views')
    
    @app.get '/show/:filename',( req, res ) ->
      fullPath = Path.join(__dirname,"..","views" ,req.params.filename )
      res.sendfile( fullPath)
      
    @app.get '/', (req, res) ->
      res.sendfile( Path.join(__dirname, '/../views/index.html') )
      
    @app.use "/static", Express.static( Path.join(__dirname,"..",'media') )

      
  setupSocketIO: ->
    @app.io.sockets.on 'connection', (socket) =>
      user = @users.addUser(@)      
      socket.emit "welcome", {
        "name": user.name
      }
      socket.on 'disconnect', =>
        @users.removeUser(user)
  
  loadPlugins: ( plugins, dirs, callback ) ->
    dirPaths = dirs
    if not util.isArray(dirs)
      dirPaths = [ dirs ]
      
    for pathName in dirPaths
      loader = new Loader( pathName, @ )
      loader.loads()
      [].push.apply( plugins,loader.plugins )
      
      for plugin in loader.plugins
        callback( plugin ) if callback?
                

module.exports = Sparrow  