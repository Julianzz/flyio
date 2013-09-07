{ EventEmitter } = require

class Robot
  constructor: (name="flyio")->
    @name      = name
    @events    = new EventEmitter
    