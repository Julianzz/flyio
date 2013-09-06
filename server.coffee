app = require('express.io')()
users = require("./users")
Vfs = require("vfs-local")
FileList = require("./filelist")

app.http().io()
app.io.route 'ready', (req) ->
  console.log("reay")
  req.io.emit 'talk',
    message: 'io event from an io route on the server'

#app.set('view engine', 'jade')
app.set('views', __dirname + '/views')
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/views/index.html')

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

app.listen(7076)