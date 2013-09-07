EventEmitter = require("events").EventEmitter

eventbus = new EventEmitter()

module.exports = {
  on: eventbus.on.bind(eventbus)
  emit: eventbus.emit.bind(eventbus)
  removeAllListeners: eventbus.removeAllListeners.bind(eventbus)
  removeListener: eventbus.removeListener.bind(eventbus)
}
