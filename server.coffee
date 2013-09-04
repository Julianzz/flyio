app = require('express.io')()
users = require("./users")
Vfs = require("vfs-local")
FileList = require("./filelist")

filelist = new FileList

options = 
  root: "/"

vfs = Vfs(options)

options = 
  path: "./"

console.log(filelist)
filelist.exec options,vfs, (data)->
    console.log data
  ,(code, stderr)->
    console.log(code,stderr)

app.http().io()
app.io.route 'ready', (req) ->
  console.log("reay")
  req.io.emit 'talk', 
    message: 'io event from an io route on the server' 
    
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

app.io.sockets.on 'connection', (socket) ->
  user = users.addUser() 
  
  socket.emit "welcome", user 
  socket.on 'disconnect', ->
    users.removeUser(user);

  socket.on "click", ->
    user.clicks += 1

    app.io.sockets.emit "win", { 
      message: "<strong>" + user.name + "</strong> rocks!" 
    }

app.listen(7076)