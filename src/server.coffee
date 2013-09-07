app = require('express.io')()
users = require("./users")
Vfs = require("vfs-local")
express = require("express")
FileList = require("./filelist")
EventEmitter = require("events").EventEmitter

vfsLocal = require("vfs-local")

eventEmitter = new EventEmitter()
vfs = vfsLocal({ root: "/Users/lzz/Sparrow/flyio/" })
vfs.env = {}


app.http().io()
app.io.route 'ready', (req) ->
  console.log("reay")
  req.io.emit 'talk',
    message: 'io event from an io route on the server'

#app.set('view engine', 'jade')
app.set('views', __dirname + '/views')
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/views/index.html')

restful = require('vfs-http-adapter')("/files", vfs)
app.use restful
app.use "/tmp", (req,resp,next ) ->
  console.log '%s %s', req.method, req.url
  next()

app.use(express.static(__dirname + '/public'))
console.log app.routes
console.log app.middleware

app.io.sockets.on 'connection', (socket) ->
  user = users.addUser()
  
  socket.emit "welcome", user
  socket.on 'disconnect', ->
    users.removeUser(user)

  socket.on "click", ->
    user.clicks += 1

    app.io.sockets.emit "win", {
      message: "<strong>" + user.name + "</strong> rocks!"
    }
    
  socket.on "filelist", ->
    options =
      path : "./data/"
    filelist = new FileList()
    filelist.exec options, vfs,( data ) ->
      console.log data
      socket.emit "filelist", { data: data }
    , (err, data )->
      console.log err,data if err
      console.log err,data
      

app.listen(7076)