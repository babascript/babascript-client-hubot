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
  robot.router.post "/babascript/mail/send/:mail", (req, res) ->
    url = "https://api.mailgun.net/v2/"
    data = req.body
    to = req.params.mail
    message =
      from: "Babascript <#{data.cid}@babascript.org>"
      to: to
      subject: "[babascript] please reply 'return value'"
      text: data.key
      html: data.key
    robot.brain.data.users[req.params.mail] = data
    agent.post(url+"babascript.org/messages")
    .auth("api", "key-1p4hbnz6ocpk89u5fefy9kj80eur9wx9")
    .type("form").send(message).end (err, response) ->
      throw err if err
      url = "http://babascript-hubot.herokuapp.com/babascript/mail/receive"
      message2 =
        priority: 11
        description: 'forwarding'
        expression: "match_recipient('#{data.cid}@babascript.org')"
        action: "forward('#{url}')"
      agent.post(url+"routes").auth("api", "key-1p4hbnz6ocpk89u5fefy9kj80eur9wx9")
      .type("form").send(message2).end (err, response2) ->
        console.log err
        console.log response2
        res.send 200

  robot.router.post "/babascript/mail/receive/", (req, res) ->
    console.log req.body
    res.send 200


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
      msg.send "@#{username} 研究しろよ"
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
      robot.brain.data.users["slack:#{username}"] = null
