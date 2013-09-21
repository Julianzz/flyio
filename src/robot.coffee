Robot   = require('hubot').Robot
Path    = require('path')
Fs      = require("fs")

class SparrowRobot extends Robot
  
  constructor:( @app ) ->
    @adapterPath = __dirname+"/hubot/"
    super @adapterPath,"http_adapter"

  loadAdapter: (path, adapter) ->
   @logger.info "Sparrow Loading adapter #{adapter}"
   try
     path = "#{path}/#{adapter}"
     @adapter = require(path).use @
   catch err
     @logger.error "Cannot load adapter #{adapter} - #{err}"
     process.exit(1)
     
loadScripts = (robot) ->
  return ->
    scriptsPath = Path.resolve ".", "node_modules","hubot","src","scripts"
    robot.load scriptsPath

    scriptsPath = Path.resolve ".", "src", "scripts"
    robot.load scriptsPath

    scriptsPath = Path.resolve __dirname, "hubot", "scripts"
    robot.load scriptsPath


    hubotScripts = Path.resolve ".", "hubot-scripts.json"
    Fs.exists hubotScripts, (exists) ->
      if exists
        Fs.readFile hubotScripts, (err, data) ->
          if data.length > 0
            try
              scripts = JSON.parse data
              scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
              robot.loadHubotScripts scriptsPath, scripts
            catch err
              console.error "Error parsing JSON data from hubot-scripts.json: #{err}"
              process.exit(1)

    externalScripts = Path.resolve ".", "external-scripts.json"
    Fs.exists externalScripts, (exists) ->
      if exists
        Fs.readFile externalScripts, (err, data) ->
          if data.length > 0
            try
              scripts = JSON.parse data
            catch err
              console.error "Error parsing JSON data from external-scripts.json: #{err}"
              process.exit(1)
            robot.loadExternalScripts scripts

exports.use = (@app) ->
  robot = new SparrowRobot(@app)  
  robot.adapter.on 'connected', loadScripts(robot)
  robot.run()
  exports.robot = robot
  return robot
  