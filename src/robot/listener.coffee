logger = require "../log"

class Listener
  
  constructor: ( @match. @callback) ->
    
  call: (message) ->
    if match = @matcher message
      log.debug \
        "Message '#{message}' matched regex /#{inspect @regex}/" if @regex

      @callback new @robot.Response(@robot, message, match)
      true
    else
      false
  