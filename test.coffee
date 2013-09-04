pm = require("./process_manager")
shell = require("./runner/shell")
assert = require("assert")
EventEmitter = require("events").EventEmitter

vfsLocal = require("vfs-local")

eventEmitter = new EventEmitter()
vfs = vfsLocal({ root: "/" }) 
vfs.env = {}

manager = new pm.ProcessManager({
  "shell": shell.factory(vfs)
  }, eventEmitter)

console.log manager.spawn
manager.spawn "shell", {
  command: "ls",
  args: ["-l"],
  cwd: __dirname,
  env: {}
}, "shell", (err, pid) ->
  assert.equal(err, null);
  
  processes = manager.ps();
  assert.equal(processes[pid].command, "ls -l");
  assert.equal(processes[pid].type, "shell");
  console.log processes
  eventEmitter.on "shell", (msg) ->
    
    if msg.type == "shell-exit" 
      processes =manager.ps()
      assert.equal(processes[pid], null)
      return 
    if msg.type == "shell-data"
      console.log msg.data.toString()
