pm = require "./process_manager"

exports.tcpChecker = ( port, eventName = "checker", tcpIntervals = [500, 1000, 2000, 4000, 8000] ) ->
  index = 0
  checkTCP = ->
    pm.exc "shell", { command: "lsof",args: ["-i", ":"+ port ] }, (code, stdout, stderr ) ->
      return if code
      if stdout
        msg =
          "type": runnerId + "-web-start"
          "pid": child.pid
          "url": child.url
        @eventEmitter.emit(eventName, msg)
      else if ++i < tcpIntervals.length
        setTimeout checkTCP, tcpIntervals[i]

  setTimeout checkTCP, tcpIntervals[i]
