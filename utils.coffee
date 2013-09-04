
Util = require('util');
_ = require('underscore')

exports.extend = (dest, src, noOverwrite) ->
  for prop of src
    if !noOverwrite or typeof dest[prop] == 'undefined'
      dest[prop] = src[prop];
  return dest


exports.escapeRegExp = (str) ->
  return str.replace(/([.*+?^${}()|[\]\/\\])/g, '\\$1')
  

exports.arrayToMap = (arr) ->
  map = {}
  for i in arr
    map[i] = 1
  return map

levels =
  'info':  [`'\033[90m'`, `'\033[39m'`] # grey
  'error': [`'\033[31m'`, `'\033[39m'`] # red
  'fatal': [`'\033[35m'`, `'\033[39m'`] # magenta
  'exit':  [`'\033[36m'`, `'\033[39m'`] # cyan

_slice = Array.prototype.slice

exports.log = ->
  args = _slice.call(arguments)
  lastArg = args[args.length - 1]

  level = if levels[lastArg] then args.pop() else 'info'
  
  return if !args.length

  msg = ( args.map (arg) ->
      return if typeof arg != 'string' then  Util.inspect(arg) else arg
    ).join(' ')
    
  pfx = levels[level][0] + '[' + level + ']' + levels[level][1]

  _.each msg.split('\n'), (line) ->
      console.log(pfx + ' ' + line)
