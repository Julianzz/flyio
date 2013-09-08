// Generated by CoffeeScript 1.6.2
(function() {
  var ProcessManager, async, eventEmitter, eventbus, pm, runners, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  async = require("asyncjs");

  _ = require("underscore");

  eventbus = require("./eventbus");

  ProcessManager = (function() {
    function ProcessManager(runners, eventEmitter) {
      this.runners = runners;
      this.eventEmitter = eventEmitter;
      this.prepareShutdown = __bind(this.prepareShutdown, this);
      this.processes = {};
    }

    ProcessManager.prototype.destroy = function() {
      var ps;

      this.disposed = true;
      this.clearInternal(this.shutDownInternal);
      ps = this.ps();
      return _.each(ps, this.kill);
    };

    ProcessManager.prototype.prepareShutdown = function(callback) {
      var processCount,
        _this = this;

      processCount = 0;
      return this.shutDownInterval = setInterval((function() {
        processCount = _.size(_this.ps());
        if (!processCount) {
          return callback();
        }
      }), 100);
    };

    ProcessManager.prototype.kill = function(pid, callback) {
      var child;

      if (typeof callback !== "function") {
        callback = function() {};
      }
      child = this.processes[pid];
      if (!child) {
        return callback("Process does not exist");
      }
      child.killed = true;
      child.kill("SIGKILL");
      return callback();
    };

    ProcessManager.prototype.debug = function(pid, debugMessage, callback) {
      var child;

      child = this.processes[pid];
      if (!child || !child.pid) {
        return callback("Process is not running: " + pid);
      }
      if (!child.debugCommand) {
        return callback("Process does not support debugging: " + pid);
      }
      child.debugCommand(debugMessage);
      return callback();
    };

    ProcessManager.prototype.runnerTypes = function() {
      var exclude;

      exclude = ["npm", "shell", "run-npm", "other"];
      return _.filter(_.keys(this.runners), function(runner) {
        return exclude.indexOf(runner) === -1;
      });
    };

    ProcessManager.prototype.exec = function(runnerId, options, onStart, onExit) {
      var runnerFactory, self,
        _this = this;

      self = this;
      if (this.disposed) {
        return onStart("cannot run script - the process", " manager has already been disposed");
      }
      runnerFactory = this.runners[runnerId];
      if (!runnerFactory) {
        return onStart("Could not find runner with ID ", +runnerId);
      }
      return runnerFactory(options, this.eventEmitter, "", function(err, child) {
        if (err) {
          return onStart(err);
        }
        return child.exec(function(err, pid) {
          if (err) {
            return onStart(err);
          }
          self.processes[child.pid] = child;
          return onStart(null, child.pid);
        });
      }, onExit);
    };

    ProcessManager.prototype.ps = function() {
      var child, list, pid, _ref;

      list = {};
      _ref = this.processes;
      for (pid in _ref) {
        child = _ref[pid];
        if (!child.pid || child.killed) {
          delete this.processes[pid];
        } else {
          list[pid] = child.describe();
          list[pid].extra = child.extra;
        }
      }
      return list;
    };

    ProcessManager.prototype.execCommands = function(runnerId, cmds, callback) {
      var err, out,
        _this = this;

      out = "";
      err = "";
      return async.list(cmds).each(function(cmd, next) {
        var runner;

        runner = _this.exec(runnerId, cmd, function(err, pid) {
          if (err) {
            return next(err);
          }
        }, function(code, stdout, stderr) {
          out += stdout;
          err += stderr;
          if (code) {
            return next("Error: " + code + " " + stderr, stdout);
          }
          return next();
        });
        return runner.end(function(err) {
          return callback(err, out);
        });
      });
    };

    ProcessManager.prototype.spawn = function(runnerId, options, eventName, callback) {
      var runnerFactory,
        _this = this;

      if (this.disposed) {
        return callback("cannot run script - the process manager ", "has already been disposed");
      }
      runnerFactory = this.runners[runnerId];
      if (!runnerFactory) {
        return callback("Could not find runner with ID " + runnerId);
      }
      return runnerFactory(options, this.eventEmitter, eventName, function(err, child) {
        if (err) {
          return callback(err);
        }
        return child.spawn(function(err) {
          if (err) {
            return callback(err);
          }
          _this.processes[child.pid] = child;
          callback(null, child.pid, child);
          return _this.tcpChecker(runnerId, child, eventName);
        });
      });
    };

    ProcessManager.prototype.tcpChecker = function(runnerId, child, eventName) {
      var checkTCP, i, self, tcpIntervals;

      self = this;
      if (_.indexOf(this.runnerTypes(), runnerId) === -1) {
        return;
      }
      i = 0;
      tcpIntervals = [500, 1000, 2000, 4000, 8000];
      checkTCP = function() {
        return this.exec("shell", {
          command: "lsof",
          args: ["-i", ":" + (child.port || 8080)]
        }, (function(err, pid) {}), function(code, stdout, stderr) {
          var msg;

          if (code) {
            return;
          }
          if (stdout) {
            msg = {
              "type": runnerId + "-web-start",
              "pid": child.pid,
              "url": child.url
            };
            return this.eventEmitter.emit(eventName, msg);
          } else if (++i < tcpIntervals.length) {
            return setTimeout(checkTCP, tcpIntervals[i]);
          }
        });
      };
      return setTimeout(checkTCP, tcpIntervals[i]);
    };

    return ProcessManager;

  })();

  runners = {};

  eventEmitter = eventbus;

  pm = new ProcessManager(runners, eventEmitter);

  module.exports = {
    ProcessManager: ProcessManager,
    ps: function(callback) {
      return callback(null, pm.ps());
    },
    runnerTypes: function(callback) {
      return callback(null, pm.runnerTypes());
    },
    debug: pm.debug.bind(pm),
    spawn: pm.spawn.bind(pm),
    exec: function(runnerId, options, callback) {
      return pm.exec(runnerId, options, function(err, pid) {
        if (err) {
          return callback(err);
        }
      }, callback);
    },
    kill: pm.kill.bind(pm),
    addRunner: function(name, runner) {
      return runners[name] = runner;
    },
    execCommands: pm.execCommands.bind(pm),
    destroy: pm.destroy.bind(pm),
    prepareShutdown: pm.prepareShutdown.bind(pm)
  };

}).call(this);