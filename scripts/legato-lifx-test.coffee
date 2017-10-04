legato = require('../lib/legato')

console.log('------------------------')
console.log(legato.lifx)

legato.lifx.on 'light-new', (light) ->
  console.log('discovered light')
  console.log('----------------')
  console.log(light)

legato.lifx.init()
