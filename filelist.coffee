Os = require("os")
Path = require("path")
_ = require("underscore")


class FileList

  constructor: ->
    @env = 
      findCmd: "find"
      perlCmd: "perl"
      platform: Os.platform()
      basePath: ""
      workspaceId: ""
  
  setEnv : (newEnv) ->
    self = @
    _.each this.env, (key,value) =>
      if key in newEnv 
        @env[key] = newEnv[key]


  exec: (options, vfs, onData, onExit) ->
    path = options.path
    if not options.path
        return onExit(1, "Invalid path") 

    options.uri = path
    options.path = Path.normalize( @env.basePath + (path ? "/" + path : "") ) 
    
    if Path.relative(@env.basePath, options.path).indexOf("../") is 0 
      return onExit(1, "Invalid path")

    args = @assembleCommand(options)

    vfs.spawn args.command, { 
      args: args,
      cwd: options.path,
      stdoutEncoding: "utf8",
      stderrEncoding: "utf8"
    }, (err, meta) ->
      if err or not meta.process
        return onExit(1, err)

      stderr = ""
      meta.process.stdout.on "data", (data) ->
        onData(data)

      meta.process.stderr.on "data", (data) ->
        stderr += data

      meta.process.on "exit", (code)->
        onExit(code, stderr)

  assembleCommand: (options) ->
    excludeExtensions = [
      "\\.gz"
      "\\.bzr"
      "\\.cdv"
      "\\.dep"
      "\\.dot" 
      "\\.nib"
      "\\.plst"
      "_darcs"
      "_sgbak" 
      "autom4te\\.cache"
      "cover_db"
      "_build"
      "\\.tmp" 
      "\\.pyc" 
      "\\.class"
    ]
    excludeDirectories = [
      "\\.c9revisions"
      "\\.architect"
      "\\.sourcemint"
      "\\.git"
      "\\.hg"
      "\\.pc"
      "\\.svn"
      "blib"
      "CVS"
      "RCS", "SCCS"
      "\\.DS_Store"
    ]
    excludeAbsoluteDirectories = [
      "/proc"
      "/sys"
      "/mnt"
    ]

    args = ["-n", "10", @env.findCmd ] 
    args.command = "nice"

    if @env.platform == "darwin"
      args.push("-E")
    else
      args.push("-O3")
    args.push("-P", ".", "-type", "f", "-mount", "-a")


    if not options.showHiddenFiles 
      args.push("(", "!", "-regex", ".*\/\\..*", "-or", "-name", ".htaccess", ")");

    if !!options.maxdepth
      args.push("-maxdepth", options.maxdepth);
    
    _.each excludeExtensions,(pattern) ->
      args.push("(", "!", "-regex", ".*\\/" + pattern + "$", ")")
    
    _.each excludeDirectories, (pattern) ->
      args.push("(", "!", "-regex", ".*\\/" + pattern + "\\/.*", ")")
    
    _.each excludeAbsoluteDirectories, (dir) ->
      args.push("(", "!", "-path", dir, ")")

    if @.env.platform != "darwin"
      args.push("-regextype", "posix-extended", "-print") 
      
    return args
    
module.exports = FileList