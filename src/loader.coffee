Path      = require "path"
Fs        = require "fs"
Log       = require "log"
Path      = require "path"
log       = require "./log"

class Loader
  
  constructor: ( path,params...) ->
    @plugins = []
    @path = path
    @params = params
    @logger = if log? then log else new Log("info")
    
  loads: ( init = true )->
    
    if not Fs.existsSync(@path)
      @logger.error( "path does not exists: #{@path} " )
      return
      
    for file in Fs.readdirSync(@path)
      @loadFile(@path,file,init)
        
  loadFile:(path,file,init=true) ->
    extName = Path.extname(file)
    if not ( extName is ".coffee" or extName is ".js" )
      return 
      
    fullPath = Path.join(path, Path.basename(file, extName ) )
    try
      plugin = require fullPath
      
      if init
        #invoke init class 
        if typeof plugin is "function"
          plugin = plugin @params...
        else if plugin.setup?
          plugin = plugin.setup @params...
        
      @plugins.push plugin
      @logger.info "load module file: #{fullPath}"
      
    catch error
      @logger.error "Unable to load #{fullPath}: #{error.stack}"
      process.exit(1)

module.exports = Loader

    
    
  
    