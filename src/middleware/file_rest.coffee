module.exports = (app)->
  
  urlPrefix = app.conf.get("filerest")
  if not urlPrefix
    app.logger.error("file restfule is not exists")
    process.exit(-1)
  
  adapter = require('vfs-http-adapter')(urlPrefix, app.vfs)
  stack = require('stack')( adapter )
  
  return ( req, res,next ) ->
    if not (req.url.indexOf( urlPrefix ) == 0)
      return next()
    stack( req, res, next)
    
    
