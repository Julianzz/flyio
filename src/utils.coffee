###
  some common function used by other module
###
_             = require 'underscore'
fs            = require "fs"
path          = require "path"
async         = require "async"
{execFile}    = require "child_process"
{Stream}      = require "stream"
util          = require 'util'

exports = module.exports

exports.extend = (dest, src, noOverwrite) ->
  for prop of src
    if !noOverwrite or typeof dest[prop] == 'undefined'
      dest[prop] = src[prop]
  return dest

exports.escapeRegExp = (str) ->
  return str.replace(/([.*+?^${}()|[\]\/\\])/g, '\\$1')

# translate array into map
exports.arrayToMap = (arr) ->
  map = {}
  for i in arr
    map[i] = 1
  return map

# Asynchronously and recursively create a directory if it does not
# already exist. Then invoke the given callback.
exports.mkdirp = (dirname, callback) ->
  fs.lstat (p = path.normalize dirname), (err, stats) ->
    if err
      paths = [p].concat(p = path.dirname p until p in ["/", "."])
      async.forEachSeries paths.reverse(), (p, next) ->
        fs.exists p, (exists) ->
          if exists then next()
          else fs.mkdir p, 0o755, (err) ->
            if err then callback err
            else next()
      , callback
    else if stats.isDirectory()
      callback()
    else
      callback "file exists"

# A wrapper around `chown(8)` for taking ownership of a given path
# with the specified owner string (such as `"root:wheel"`). Invokes
# `callback` with the error string, if any, and a boolean value
# indicating whether or not the operation succeeded.
exports.chown = (path, owner, callback) ->
  error = ""
  exec ["chown", owner, path], (err, stdout, stderr) ->
    if err then callback err, stderr
    else callback null

# Capture all `data` events on the given stream and return a function
# that, when invoked, replays the captured events on the stream in
# order.
exports.pause = (stream) ->
  queue = []

  onData  = (args...) -> queue.push ['data', args...]
  onEnd   = (args...) -> queue.push ['end', args...]
  onClose = -> removeListeners()

  removeListeners = ->
    stream.removeListener 'data', onData
    stream.removeListener 'end', onEnd
    stream.removeListener 'close', onClose

  stream.on 'data', onData
  stream.on 'end', onEnd
  stream.on 'close', onClose

  ->
    removeListeners()

    for args in queue
      stream.emit args...

# Single-quote a string for command line execution.
exports.quote = (string) -> "'" + string.replace(/\'/g, "'\\''") + "'"

# Generate and return a unique temporary filename based on the
# current process's PID, the number of milliseconds elapsed since the
# UNIX epoch, and a random integer.
exports.makeTemporaryFilename = ->
  tmpdir    = process.env.TMPDIR ? "/tmp"
  timestamp = new Date().getTime()
  random    = parseInt Math.random() * Math.pow(2, 16)
  filename  = "pow.#{process.pid}.#{timestamp}.#{random}"
  path.join tmpdir, filename

# Read the contents of a file, unlink the file, then invoke the
# callback with the contents of the file.
exports.readAndUnlink = (filename, callback) ->
  fs.readFile filename, "utf8", (err, contents) ->
    if err then callback err
    else fs.unlink filename, (err) ->
      if err then callback err
      else callback null, contents
        
# Execute a command without spawning a subshell. The command argument
# is an array of program name and arguments.
exports.exec = (command, options, callback) ->
  unless callback?
    callback = options
    options = {}
  execFile "/usr/bin/env", command, options, callback