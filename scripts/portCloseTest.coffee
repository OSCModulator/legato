midi = require('midi')

input = new midi.input()
for i in [0..4]
  console.log i, '> opening'
  input.openPort(2)
  console.log i, '< closing'
  input.closePort()
  console.log '---------------'

