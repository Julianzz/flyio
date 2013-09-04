Moniker = require('moniker')

class User
  constructor: ->
    @users = {} 
    
  addUser: ->
    name = Moniker.choose()
    user = 
      name: name
      clicks: 0
  
    @users[name] = user
    @updateUsers()
    return user
    
  removeUser: (user) ->
    if user.name in @users
      delete @users[user.name]
    return user
  
  updateUsers: (callback) ->
    str = '';
    for user of @users
        str += user.name + ' <small>(' + user.clicks + ' clicks)</small>'
        
    callback( str ) if callback

module.exports = new User