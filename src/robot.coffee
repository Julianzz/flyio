app = require('express.io')

{ EventEmitter } = require

class Robot
  constructor: (name="flyio")->
    @name      = name
    @events    = new EventEmitter
    @app = app()
    
  init: ->

  initExpress: ->
    app.set('views', __dirname + '/../views')
    app.get '/', (req, res) ->
      res.sendfile(__dirname + '/../views/index.html')
      
  listen: ->
  