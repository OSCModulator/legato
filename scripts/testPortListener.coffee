midi = require 'midi'

input = new midi.input()

logPorts = ->
  console.log '--- IN ---'
  console.log 'port count: ', input.getPortCount()
  for i in [0..input.getPortCount() - 1]
    console.log '>', input.getPortName(i)

openPort = (name) ->
  for i in [0..input.getPortCount() - 1]
    if input.getPortName(i) is name
      input.openPort(i)


logPorts()
console.log '--------------------------------------'

input.on 'message', (delta, message) ->
  console.log "--> [#{delta}]", message

openPort('TestPort')

