
fs         = require "fs"
path       = require "path"
async      = require "async"
{execFile} = require "child_process"
{Stream}   = require "stream"

exports = module.exports

exports.LineBuffer = class LineBuffer extends Stream
  
  constructor: (@stream) ->
    @readable = true
    @_buffer = ""

    self = @
    @stream.on 'data', (args...) -> self.write args...
    @stream.on 'end',  (args...) -> self.end args...

  write: (chunk) ->
    @_buffer += chunk

    # If there's a newline in the buffer, slice the line from the
    # buffer and emit it. Repeat until there are no more newlines.
    while (index = @_buffer.indexOf("\n")) != -1
      line     = @_buffer[0...index]
      @_buffer = @_buffer[index+1...@_buffer.length]
      @emit 'data', line

  # Process any final lines from the underlying stream's `end`
  # event. If there is trailing data in the buffer, emit it.
  end: (args...) ->
    if args.length > 0
      @write args...
    @emit 'data', @_buffer if @_buffer.length
    @emit 'end'

# Read lines from `stream` and invoke `callback` on each line.
exports.bufferLines = (stream, callback) ->
  buffer = new LineBuffer stream
  buffer.on "data", callback
  buffer