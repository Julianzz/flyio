module.exports = (robot) ->
  robot.catchAll (msg) ->
    console.log "inside catch all,msg"
    msg.send "error commands,please check help"