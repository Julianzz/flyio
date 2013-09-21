
Log   = require 'log'
_     = require "underscore"
util  = require "util"

log = new Log("info")   
levels =
  'info':  [`'\033[90m'`, `'\033[39m'`] # grey
  'error': [`'\033[31m'`, `'\033[39m'`] # red
  'fatal': [`'\033[35m'`, `'\033[39m'`] # magenta
  'exit':  [`'\033[36m'`, `'\033[39m'`] # cyan

logFunc = ->
  args = _slice.call(arguments)
  lastArg = args[args.length - 1]

  level = if levels[lastArg] then args.pop() else 'info'
  
  return if !args.length

  msg = ( args.map (arg) ->
    return if typeof arg != 'string' then  util.inspect(arg) else arg
  ).join(' ')
    
  pfx = levels[level][0] + '[' + level + ']' + levels[level][1]

  _.each msg.split('\n'), (line) ->
    console.log(pfx + ' ' + line)
    
_slice = Array.prototype.slice


for name, level of levels
  module.exports[name] = (args...) ->
    logFunc name,args...


