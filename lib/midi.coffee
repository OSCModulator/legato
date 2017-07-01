'user strict'

L = utils = midi = parser = midiInputQuery = midiOutputQuery = ___ = null

@inject = (router, legatoUtils, rtMidi, midiHelp) ->
  L = router
  utils = legatoUtils
  midi = rtMidi
  parser = midiHelp
  ___ = utils.____ '[midi]'

# Parse method copied from https://github.com/hhromic/midi-utils-js/blob/master/midiparser.js#L418
# TODO Remove this parser in favor of midiHelp or if we continue to use this code, include the MIT
# license as required by midiparser.js.
parse = (port, msg) ->
  type = msg[0] & 0xF0
  channel = msg[0] & 0x0F
  switch type
    when 0xB0
      note = msg[1] & 0x7F
      velocity = (msg[2] & 0x7F)/127.0
      ["/#{channel}/cc/#{note}", velocity]
    when 0x90
      note = msg[1] & 0x7F
      velocity = (msg[2] & 0x7F)/127.0
      ["/#{channel}/note/#{note}", velocity]
    when 0x80
      note = msg[1] & 0x7F
      ["/#{channel}/note/#{note}", 0]
    when 0xE0
      value = (msg[1] & 0x7F)/127.0
      ["/#{channel}/pitch-bend/", value]
    when 0xA0
      pressure = (msg[1] & 0x7F)/127.0
      ["/#{channel}/key-pressure/", pressure]
    when 0xC0
      number = bytes[1] & 0x7F
      ["/#{channel}/program-change/#{number}", 0 ]
    when 0xD0
      pressure = bytes[1] & 0x7F
      ["/#{channel}/channel-pressure/#{pressure}", 0]
    else
      ___ 'unknown message:', msg...


# Returns a function that can be called to start listening on a midi port.
# @param port {int} The index of the port to open.
# @param virtual {boolean} Whether we are opening a virtual port. Virtual is used if you wish to
# open a new port as opposed to connecting to an existing port.
# @return {Function} A function that can be called to start listening on this port.
#     The returned function takes the following parameters.
#     @param router {Function} The callback that will be called when new messages are received. This
#         function is created by legato and will check all registered routes for matching paths.
#     @return {Function} A function that should be called to close down this listener.
@In = (port, virtual=no) ->
  (router) ->
    ___ "in: open #{virtual and 'virtual ' or ''}port #{port}"
    input = new midi.input()

    # TODO Should we guard against opening virtual ports on systems that don't provide them?
    input["open#{virtual and 'Virtual' or ''}Port"] port
    input.on 'message', (deltaTime, msg) ->
      ___ "[#{deltaTime}] received midi #{msg}"
      router parse(port, msg)...
    return ->
      input.closePort()
      ___ "in: port #{port} close"

# Returns a function that can be used to send a midi message on the port passed.
#
# @param port {int | string} If you wish to open your own midi port, this will be the name of your
#   midi port. If you wish to connect to an existing port, this is the port id 0-N. If you
#   pass ({int}, false), your int will be the new port name (which is probably not what you intend).
#
# @param virtual {boolean} If true, you are opening a virtual port. If false, you intend to 
#   send messages on an existing port (default). Sending on an existing port will fail if that
#   port doesn't exist yet.
#
# @return {Function} A function that can be called to send a midi message on the port you 
# specified.
#   The function takes the following parameters:
#   @param type {String} The type of message to send as described at 
#   https://github.com/charlesholbrow/midi-help#documentation
#
#   Depending on the type of message to send, you can pass other parameters such as:
#
#   note {int} The note number to send.
#   channel {int} The channel to send on (0-15).
#   value {int} The note value to send (0-127).
# TODO Make it possible to use the port name to open an existing port. In this case
# we would loop through the port names looking for a matching name and then open the
# port at that index.
@Out = (port, virtual=no) ->
  ___ "out: open #{virtual and 'virtual ' or ''}port #{port}"
  output = new midi.output()
  output["open#{virtual and 'Virtual' or ''}Port"] port

  # Store it so it can be destroyed later.
  utils.store ->
    output.closePort()
    ___ "out: port #{port} close"

  (type, rest...) ->
    # Normalize the value parameter which is passed in a different position
    # based on the type of message.
    switch type
      when 'pitchBend', 'channelPressure' then index = 0
      when 'songPosition' then index = 50 # Use the value as passed.
      else index = 1

    if rest.length >= index
      rest[index] = parseInt(rest[index] * 127)

    parsed = parser[type].apply(parser, rest)
    ___ "out #{parsed}"
    output.sendMessage(parsed)


# TODO We could use node-usb to discover when new USB devices
# are connected to the system and then rescan. If we do that,
# it would probably make sense to emit an event from this class.
@ins = ->
  ___ "in: retrieving available ports."
  if not midiInputQuery then midiInputQuery = new midi.input()

  ___ "in: total open ports #{midiInputQuery.getPortCount()}"
  for i in [0...midiInputQuery.getPortCount()]
    ___ "in: port #{i} is #{midiInputQuery.getPortName(i)}"
    midiInputQuery.getPortName i

@outs = ->
  ___ "out: retrieving available ports."
  if not midiOutputQuery then midiOutputQuery = new midi.output()

  ___ "out: total open ports #{midiOutputQuery.getPortCount()}"
  for o in [0...midiOutputQuery.getPortCount()]
    ___ "out: port #{o} is #{midiOutputQuery.getPortName(o)}"
    midiOutputQuery.getPortName o

