midi = require('midi')

input = new midi.input()
output = new midi.output()

logPorts = ->
  console.log '--- IN ---'
  console.log 'port count: ', input.getPortCount()
  for i in [0..input.getPortCount() - 1]
    console.log '>', input.getPortName(i)

  console.log '--- OUT ---'
  console.log 'port count:', output.getPortCount()
  for i in [0..output.getPortCount() - 1]
    console.log '>', output.getPortName(i)

openPort = (name) ->
  for i in [0..input.getPortCount() - 1]
    if input.getPortName(i) is name
      input.openPort(i)


logPorts()
console.log '--------------------------------------'

console.log 'opening TestPort'
output.openVirtualPort('TestPort')

console.log '--------------------------------------'
logPorts()
console.log '--------------------------------------'

setInterval ->
  outputMessage = [176,22,1]
  output.sendMessage outputMessage
  console.log "-->", outputMessage
, 3000

