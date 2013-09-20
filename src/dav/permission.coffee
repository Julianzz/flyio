jsDAV_ServerPlugin = require("jsDAV/lib/DAV/plugin").jsDAV_ServerPlugin
util = require("util")


Permission = module.exports = (handler) ->
  jsDAV_ServerPlugin.call(@, handler) 

  @handler = handler;
  #handler.addEventListener("beforeMethod", @checkPermission.bind(@))


util.inherits(Permission, jsDAV_ServerPlugin)

do ->

  @READ_METHODS = {
    "OPTIONS":1
    "GET":1
    "HEAD":1
    "PROPFIND":1
    "REPORT":1
  }

  @WRITE_METHODS = {
    "DELETE":1
    "MKCOL":1
    "PUT":1
    "PROPPATCH":1
    "COPY":1
    "MOVE":1
    "LOCK":1
    "UNLOCK":1
  }
  
  @checkPermission = (e, method) ->
    permissions = @handler.server.permissions
    if typeof permissions == "string" 
      if (this.READ_METHODS[method] && permissions.indexOf("r") > -1)
        return e.next()

      if (this.WRITE_METHODS[method] && permissions.indexOf("w") > -1)
        return e.next()

    @handler.httpResponse.writeHead(403)
    @handler.httpResponse.end("operation not permitted!")
    e.stop()