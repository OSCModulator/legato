legato = require('../lib/legato')

getPortFor = (lookingFor) ->
  names = legato.midi.ins()
  i = -1
  for name in names
    i += 1
    if name is lookingFor
      return i
  return i

resetLegato = ->
  legato.init()
  legato.on '/:/:/:/:', -> console.log('>>> message received')
  outport = legato.midi.Out('LegatoTest', true)
  index = getPortFor('TestPort')
  inportId = legato.in( legato.midi.In(index) )

setInterval ->
  console.log '-------------------------------'
  resetLegato()
, 3000

