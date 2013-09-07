client = require('socket.io-client')

socket = client.connect 'http://localhost:30001'
socket.on 'news', (data) ->
  console.log(data)
  socket.emit 'my other event', { my: 'data' }