agent = require "superagent"

module.exports = (robot) ->
  console.log robot

  # twitter mediator
  robot.router.post "/babascript/twitter/:username", (req, res) ->
    data = req.body
    username = req.params.username.toLowerCase()
    key = data.key
    user =
      screen_name: username
      user:
        user: username
    robot.brain.data.users["twitter:#{username}"] = data
    robot.send user, key
    res.send robot.brain.data.users[username]

  robot.respond /(.*)/i, (msg) ->
    username = msg.message.user.user.toLowerCase()
    task = robot.brain.data.users[username]
    if !task?
      return
    value = msg.match[1]
    tuple =
      baba: "script"
      type: "return"
      value: value
      cid: task.cid
      worker: username
      options: {}
      name: task.groupname
      _task: task
      from: "twitter"
    service = task.service || "http://manager.babascript.org/"
    url = service + "api/webhook/#{task.cid}"
    data =
      tuple: tuple
      options: {}
      tuplespace: username
    agent.post(url).send(data).end (err, res) ->
      msg.send "ok"
      robot.brain.data.users[username] = {}

  # mail mediator
  robot.router.post "/babascript/mail/:username", (req, res) ->


  # slack mediator
  robot.router.post "/babascript/slack/:username", (req, res) ->
    data = req.body
    username = req.params.username.toLowerCase()
    robot.brain.data.users["slack:#{username}"] = data
    key = data.key
    room = data.room || "#babascript"
    text = "@#{username} #{key}"
    robot.send {room: room}, text
    res.send robot.brain.data

  robot.respond /(.*)/i, (msg) ->
    username = msg.message.user.name.toLowerCase()
    task = robot.brain.data.users["slack:#{username}"]
    if !task?
      return
    tuple =
      baba: "script"
      type: "return"
      value: msg.match[1]
      cid: task.cid
      worker: username
      options: {}
      name: task.groupname
      _task: task
      from: "slack chat"
    service = task.service || "http://manager.babascript.org/"
    url = service + "api/webhook/#{task.cid}"
    data =
      tuple: tuple
      options: {}
      tuplespace: username
    agent.post(url).send(data).end (err, res) ->
      msg.send "わかった"
      robot.brain.data.users["slack:#{username}"] = {}
