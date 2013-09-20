DavFileSystem   = require "../dav/file_system"

module.exports = (app) ->
  urlPrefix = app.conf.get("davprefix")
  if not urlPrefix
    app.logger.error("file restfule is not exists")
    process.exit(-1)
    
  options = {
    vfs: app.vfs
    urlPrefix: urlPrefix
  }
  #console.log FileSystem
  fs = new DavFileSystem( app.sandbox, options )
  
  return (req,res,next) ->
    if not (req.url.indexOf( urlPrefix ) == 0)
      return next()
      
    fs.run( req, res )