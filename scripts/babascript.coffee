debug = require('debug')('babascript:client:hubot')
Client = require 'babascript-client'
Adapter = require 'babascript-linda-adapter'

module.exports = (robot) ->
  clients = {}
  createClient = (name, room) ->
    adapter = new Adapter "http://babascript-linda.herokuapp.com", {port: 80}
    client = new Client name, {adapter: adapter}
    client.on "get_task", (task) ->
      debug task
      message = "@#{name} #{task.key}"
      user = robot.brain.data.babascript[name]
      robot.send {room: user.room}, message
      robot.brain.data.babascript[name].task = task
      robot.brain.save()
    client.on "return_value", (task) ->
      delete robot.brain.data.babascript[name].task
      robot.brain.save()
    return client

  join = (name, room) ->
    debug robot.brain.data.babascript
    robot.brain.data.babascript[name] = {room: room, task: null}
    robot.brain.save()
    clients[name] = createClient name, room

  leave = (name) ->
    debug name
    clients[name].adapter.disconnect()
    delete clients[name]
    robot.brain.data.babascript[name] = null
    robot.brain.save()

  setTimeout ->
    if !robot.brain.data.babascript?
      robot.brain.data.babascript = {}
    for k,v of robot.brain.data.babascript
      debug k,v.room
      clients[k] = createClient k, v.room
  , 2000

  robot.respond /user\sjoin/i, (msg) ->
    debug msg
    debug 'join'
    name = msg.envelope.user.name
    room = msg.envelope.room
    return msg.send "@#{name} join済み" if clients[name]?
    join name, room
    msg.send "@#{name} ok, join"


  robot.respond /user\sleave/i, (msg) ->
    debug msg
    debug 'leave'
    name = msg.envelope.user.name
    return msg.send "@#{name} joinしてない" if !clients[name]?
    leave name
    msg.send "@#{name} ok, leave"

  robot.respond /user\slist/i, (msg) ->
    message = ""
    name = msg.envelope.user.name
    for k,v of clients
      message += "#{v.id} |"
    message = "誰もいませんよ" if message is ''
    return msg.send "@#{name} #{message}"

  robot.respond /task\slist/i, (msg) ->
    name = msg.envelope.user.name
    debug robot.brain.data.babascript
    task = robot.brain.data.babascript[name].task
    if task?
      message = "#{task.key} - type is #{task.format}"
    else
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
