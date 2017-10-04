'use strict'

utils = _ = client = ___ = lights = null

@initialized = false

# Lifx dependencies
#
# @param legatoUtils
# @param lodash The lodash library
# @param lifxClient The LifxClient instance retrieved from
#     `new require('node-lifx').Client()`
#
# @return void
@inject = (legatoUtils, lodash, lifxClient) ->
  utils = legatoUtils
  _ = lodash
  client = lifxClient
  ___ = utils.____ '[lifx]'
  return

@on = (event, cb) ->
  return client.on(event, cb)

@once = (event, cb) ->
  return client.once(event, cb)

# @param opts {Object} An object used to configure the LIFX client as described
#   at https://github.com/MariusRumpf/node-lifx
# @param cb {Function} A callback function that will be notified when the
#   first light is discovered. The discovered light will be
#   passed to the callback. Only the first light discovery will
#   be sent, therefore this is equivalient to calling
#   `lifx.once('light-new', callback)`. To recieve, all new
#   light events, use `lifx.on('light-new', callback)`
@init = (opts, cb) ->
  @initialized = true
  client.init(opts)
  if cb
    client.on 'light-new', (light) ->
      ___ 'light discovered'
      # TODO Make sure this function gets removed
      # client.removeListener 'light-new', cb
      cb()
  return

# Returns a function that can be used to send a command to an existing
# Lifx light.
#
# @param id {int} The id of the light in question.
#
# @return {Function} A function that can be called to send a command to
#   the light in question. The function takes the following parameters:
#
#   @param color {hex} The color for the light. Closer to black will dim
#     the light. Closer to white will make the light brighter.
#   @param duration {int} The length of time in milliseconds to change the
#     color.
@Out = (id) ->
  light = client.light(id)
  ___ "out: creating message sender for light #{id}"

  # TODO Should we worry about cleaning anything up?

  messageRate = 1000/20
  sender = (color='#ffffff', duration=0) ->
    # TODO Make sure the light is on?
    light.colorRgbHex(color, duration)
    ___ "out: #{color} in #{duration}"

  return _.throttle( sender, messageRate, leading:true )


# Retrieve the currently discovered lights. Light discovery is
# initiated once you call the `init()` method and is asynchronous.
# It is also possible to register a listener for the 'light-new'
# event to know when new lights are discovered.
@outs = ->
  ___ 'out: retrieving available lights.'
  if not @initialized
    @init()

  return client.lights()

