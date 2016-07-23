'user strict'

class LegatoMidiPort
  _getPortKeyAtIndex: (index, entries) ->
    @_getItemAtIndex(index, entries)[0]

  _getPortAtIndex: (index, entries) ->
    @_getItemAtIndex(index, entries)[1]

  _getItemAtIndex: (index, entries) ->
    i = 0
    curr = entries.next()
    while curr and not curr.done
      if i is index
        return curr.value

      curr = entries.next()
      i += 1
    return false

  constructor: (@type) ->
    if @type isnt 'input' and @type isnt 'output' then @type = 'input'

    @_midi = null

    if navigator.requestMIDIAccess
      @_requestingMidi = navigator.requestMIDIAccess()
      @_requestingMidi.then( (midiAccess) =>
        @_midi = midiAccess
        if window
          window.midi = midiAccess
      ).catch (error) =>
        @_midi = null
        console.error('Unable to get MIDI access.', error)
    else
      console.error('navigator.requestMIDIAccess is not available.')
      @_requestingMidi = Promise.reject('navigator.requestMIDIAccess is not available.')

  ready: -> @_requestingMidi

  getPortCount: ->
    if @_midi
      switch @type
        when 'input' then return @_midi.inputs.size
        when 'output' then return @_midi.outputs.size
    return 0

  getPortName: (index) ->
    if @_midi
      # TODO There may be issues using an indexed approach with browser midi.
      # Should test what happens with adding/removing hardware in different
      # orders.
      entries = null
      switch @type
        when 'input' then entries = @_midi.inputs.entries()
        when 'output' then entries = @_midi.outputs.entries()

      port = @_getPortAtIndex(index, entries)
      return port.name

    return false

class LegatoMidiInput extends LegatoMidiPort

  _notifyListeners: (event) ->
    data = event.data
    time = event.receivedTime
    for listener in @_listeners
      listener(time, data)

  _doOpenPort: (i) ->
    # TODO If _doOpenPort is called multiple times, do we want to close the old
    # port and then connect to the new one?
    if @_midi and not @_port
      @_port = @_getPortAtIndex(i, @_midi.inputs.entries())
      # TODO Resetting the onmidimessage method below means that only one input
      # instance can listen to a midi. We should instead point onmidimessage to
      # a class level registry of port listeners.
      @_port.onmidimessage = (event) => @_notifyListeners(event)
      return true
    return false

  constructor: ->
    @_listeners = []
    super('input')

  openPort: (i) ->
    @ready().then =>
      @_doOpenPort(i)

  openVirtualPort: (i) ->
    @ready().then =>
      @_doOpenPort(i)

  on: (event, cb) ->
    @ready().then =>
      switch event
        when 'message'
          @_listeners.push cb

  closePort: ->
    @ready().then =>
      if @_port
        @_port.close()
        @_listeners = []
        @_port = null

class LegatoMidiOutput extends LegatoMidiPort
  _doOpenPort: (i) ->
    # TODO If _doOpenPort is called multiple times, do we want to close the old
    # port and then connect to the new one?
    if @_midi and not @_port
      @_port = @_getPortAtIndex(i, @_midi.outputs.entries())
      return true
    return false

  constructor: ->
    @portIndex = null
    super('output')

  openPort: (i) ->
    @ready().then =>
      @_doOpenPort(i)

  openVirtualPort: (i) ->
    @ready().then =>
      @_doOpenPort(i)

  sendMessage: (data) ->
    # TODO An asynchronous API here introduces latency.
    @ready().then =>
      if @_midi and @_port
        @_port.send(data)

  closePort: ->
    @ready().then =>
      if @_port
        @_port.close()
        @_port = null

@input = LegatoMidiInput
@output = LegatoMidiOutput

