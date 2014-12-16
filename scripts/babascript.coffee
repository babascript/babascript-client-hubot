debug = require('debug')('babascript:client:hubot')
Client = require 'babascript-client'

module.exports = (robot) ->
  clients = {}
  if !robot.brain.data.babascript?
    robot.brain.data.babascript = {}
    robot.brain.data.babascript.user = {}
    robot.brain.data.babascript.task = {}
    robot.brain.save()
  create = (name, room) ->
    client = new Client name
    clients[name] = client
    client.on "get_task", (task) ->
      debug task
      message = "@#{name} #{task.key}"
      robot.send {room: room}, message
      robot.brain.data.babascript.task[name] = task
      robot.brain.save()
    client.on "return_value", (task) ->
      delete robot.brain.data.babascript.task[name]
      robot.brain.save()

  join = (name, room) ->
    debug robot.brain.data.babascript.user
    debug robot.brain.data.babascript.user[name]
    robot.brain.data.babascript.user[name] = room
    robot.brain.save()
    create name, room

  leave = (name) ->
    debug name
    clients[name].adapter.disconnect()
    delete clients[name]
    delete robot.brain.data.babascript.user[name]
    robot.brain.save()

  for k,v of robot.brain.data.babascript.user
    create k, v

  robot.respond /babascript\sjoin/i, (msg) ->
    debug msg
    debug 'join'
    name = msg.envelope.user.name
    room = msg.envelope.room
    return msg.send "@#{name} join済み" if clients[name]?
    join name, room


  robot.respond /babascript\sleave/i, (msg) ->
    debug msg
    debug 'leave'
    name = msg.envelope.user.name
    return msg.send "@#{name} joinしてない" if !clients[name]?
    leave name

  robot.respond /babascript\slist/i, (msg) ->
    message = ""
    name = msg.envelope.user.name
    for k,v of robot.brain.data.babascript.user
      message += "#{k} |"
    message = "誰もいませんよ" if message is ''
    return msg.send "@#{name} #{message}"

  robot.respond /babascript\stask\slist/i, (msg) ->
    name = msg.envelope.user.name
    message = ""
    for k, v of robot.brain.data.babscript.task[name]
      message += robot.brain.data.babscript.task[name]
    message = "何もありませんよ"
    return msg.send "@#{name} #{message}"

  robot.respond /return\s(.*)/i, (msg) ->
    debug msg
    debug 'return value'
    name = msg.envelope.user.name
    return msg.send "@#{name} 指示はなにもない" if !clients[name]?
    value = msg.match[1]
    debug name
    debug value
    clients[name].returnValue value

# module.exports = (robot) ->
#   socket = SocketIOClient.connect API, {'force new connection': true}
#   linda = new LindaSocketIOClient().connect socket
#   cids = {}
#   linda.io.on "connect", ->
#     console.log 'connect'
#     token = process.env.NODE_BABASCRIPT_HUBOT_TOKEN
#     ts = linda.tuplespace("waiting_hubot")
#     ts.watch {baba: 'script', type: 'connect'}, (err, tuple) ->
#       console.log 'connect request'
#       id = tuple.data.id
#       # このClientは、基本的に単数であるべき
#       # というか、それ以外だときつい。
#       if cids[id]? and cids[id].linda.io.socket.open is true
#         return
#       client = new Client id, {manager: 'http://localhost:9080'}
#       client.on "get_task", (task) ->
#         console.log "get_task"
#         console.log task
#         robot.send {}, "#{@name} #{task.key}"
#         robot.brain.data.users["linda::#{@name}"] = task
#       client.on "cancel_task", (task) ->
#         console.log task
#       cids[id] = client
#     ts.watch {baba: 'script', type: 'disconnect'}, (err, tuple) ->
#       id = tuple.data.id
#       if cids[id]?
#         cids[id].linda.io.disconnect()
#         delete cids[id]
#
#   robot.respond /(.*)/i, (msg) ->
#     name = msg.message
#     console.log name
#
#   # twitter mediator
#   robot.router.post "/twitter/:username", (req, res) ->
#     data = req.body
#     username = req.params.username.toLowerCase()
#     key = data.key
#     user =
#       screen_name: username
#       user:
#         user: username
#     robot.brain.data.users["twitter:#{username}"] = data
#     robot.send user, key
#     res.send robot.brain.data.users[username]
#
#   robot.respond /(.*)/i, (msg) ->
#     username = msg.message.user.user.toLowerCase()
#     task = robot.brain.data.users[username]
#     if !task?
#       return
#     value = msg.match[1]
#     tuple =
#       baba: "script"
#       type: "return"
#       value: value
#       cid: task.cid
#       worker: username
#       options: {}
#       name: task.groupname
#       _task: task
#       from: "twitter"
#     service = task.service || "http://manager.babascript.org/"
#     url = service + "api/webhook/#{task.cid}"
#     data =
#       tuple: tuple
#       options: {}
#       tuplespace: username
#     agent.post(url).send(data).end (err, res) ->
#       msg.send "ok"
#       robot.brain.data.users[username] = {}
#
#   # mail mediator
#   robot.router.post "/mail/send/:mail", (req, res) ->
#     url = "https://api.mailgun.net/v2/"
#     data = req.body
#     to = req.params.mail
#     message =
#       from: "Babascript <#{data.cid}@babascript.org>"
#       to: to
#       subject: "[babascript] please reply 'return value'"
#       text: data.key
#       html: data.key
#     robot.brain.data.users["mail:#{to}"] = data
#     agent.post(url+"babascript.org/messages")
#     .auth("api", "key-1p4hbnz6ocpk89u5fefy9kj80eur9wx9")
#     .type("form").send(message).end (err, response) ->
#       throw err if err
#       webhook = "http://#{req.headers.host}/mail/receive"
#       message2 =
#         priority: 11
#         description: 'forwarding'
#         expression: "match_recipient('#{data.cid}@babascript.org')"
#         action: "forward('#{webhook}')"
#       agent.post(url+"routes").auth("api", "key-1p4hbnz6ocpk89u5fefy9kj80eur9wx9")
#       .type("form").send(message2).end (err, response2) ->
#         res.send 200
#
#   robot.router.post "/mail/receive", (req, res) ->
#     id = req.body.sender
#     task = robot.brain.data.users["mail:#{id}"]
#     if !task?
#       return
#     tuple =
#       baba: "script"
#       type: "return"
#       value: msg.match[1]
#       cid: task.cid
#       worker: task.username
#       options: {}
#       name: task.groupname
#       _task: task
#       from: "mail"
#     service = task.service || "http://manager.babascript.org/"
#     url = service + "api/webhook/#{task.cid}"
#     data =
#       tuple: tuple
#       options: {}
#       tuplespace: task.username
#     agent.post(url).send(data).end (err, res) ->
#       robot.brain.data.users["mail:#{id}"] = null
#       #TODO  Routes の解除をここでする
#       res.send 200
#
#
#   # slack mediator
#
#   robot.router.post "/slack/:username", (req, res) ->
#     data = req.body
#     username = req.params.username.toLowerCase()
#     robot.brain.data.users["slack:#{username}"] = data
#     key = data.key
#     room = data.room || "#babascript"
#     text = "@#{username} #{key}"
#     robot.send {room: room}, text
#     res.send robot.brain.data
#
#   robot.respond /(.*)/i, (msg) ->
#     username = msg.message.user.name.toLowerCase()
#     task = robot.brain.data.users["slack:#{username}"]
#     if !task?
#       if msg.message.text.match /^@/
#         if !robot.brain.data.zatudan?
#           robot.brain.data.zatudan = ""
#         context = robot.brain.data.zatudan
#         url = "https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue?APIKEY=#{DOCOMO_APIKEY}"
#         data = {utt: msg.match[1]}
#         if context?
#           data['context'] = context
#         agent.post(url).send(data).end (err, res) ->
#           robot.brain.data.zatudan = res.body.context
#           if err
#             msg.send "@#{username} 研究しろよ"
#           else
#             msg.send "@#{username} #{res.body.utt}"
#       return
#     tuple =
#       baba: "script"
#       type: "return"
#       value: msg.match[1]
#       cid: task.cid
#       worker: username
#       options: {}
#       name: task.groupname
#       _task: task
#       from: "slack chat"
#     service = task.service || "http://manager.babascript.org/"
#     url = service + "api/webhook/#{task.cid}"
#     data =
#       tuple: tuple
#       options: {}
#       tuplespace: username
#     agent.post(url).send(data).end (err, res) ->
#       msg.send "@{username }わかった"
#       robot.brain.data.users["slack:#{username}"] = null
