Robot   = require('hubot').Robot
Adapter = require('hubot').Adapter
TextMessage = require('hubot').TextMessage
crypto = require 'crypto'

genNewId = (callback) ->
  crypto.randomBytes 30, (e, buf) ->
    if (e)
      callback(e, null)
    callback(null, buf.toString('hex'))
    
class Http extends Adapter
  
  constructor:(args...)->
    super(args...)
    @responces= {}
    
  send: (envelope, strings...) ->
    user = envelope.user
    messageText = strings.join("\n")
    response = @responces[user.id][user.lastRequestId]
    if response?
      delete @responces[user.id][user.lastRequestId]
      response.set("Content-Type": "application/json")
      response.send({message:messageText})

  reply: (envelope, strings...) ->
    @send envelope, strings...


  run: ->
    self = @
    self.responces = {}
    
    @robot.app.post "/hubot/tell", (req, res) =>
      
      genNewId (err, id) =>
        user =  @robot.brain.userForId '1', name: 'Shell', room: 'Shell'
        user.lastRequestId = id
        messageText = req.body.message
        self.responces[user.id] ?= {}
        self.responces[user.id][id] = res
        @receive new TextMessage user, messageText
      
    self.emit 'connected'


exports.use = (robot) ->
  adapter = new Http robot
    
    
  
  
  