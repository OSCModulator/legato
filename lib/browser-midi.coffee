'user strict'

class MidiInput

  _getInputKeyAtIndex: (index, entries) ->
    @_getItemAtIndex(index, entries)[0]

  _getInputAtIndex: (index, entries) ->
    @_getItemAtIndex(index, entries)[1]

  _getItemAtIndex: (index, entries) ->
    i = 0
    curr = entries.next()
    while curr and not curr.done
      console.debug 'key', curr.value[0], 'value', curr.value[1]
      if i is index
        return curr.value

      curr = entries.next()
    return false

  _notifyListener: (event) ->
    data = event.data
    time = event.receivedTime
    for listener in @_listeners
      listener(time, data)

  _doOpenPort: (i) ->
    if @_midi and @_port
      @_port = @_getInputKeyAtIndex(i, @_midi.inputs.entries())
      console.debug 'connecting to input', @_port.name
      @_port.onmidimessage = @_notifyListener
      return true
    return false

  constructor: ->
    @_midi = @_port = @_midiPromise = null
    @_listeners = []

    if navigator.requestMIDIAccess
      @_midiPromise = navigator.requestMIDIAccess()
      @_midiPromise.then( (midiAccess) =>
        console.debug 'You now have MIDI access.', midiAccess
        @_midi = midiAccess
        # TEMP
        window.midi = midiAccess
      , (error) =>
        console.error 'Unable to get MIDI access.', error
        @_midi = false
      )

  ready: ->
    return new Promise (resolve, reject) =>
      if @_midi
        resolve(true)
        return true
      else
        @_midiPromise.then =>
          resolve(@_midi isnt null)
        , =>
          reject(false)
        return false

  getPortCount: ->
    if @_midi
      return @_midi.inputs.size
    return 0

  getPortName: (index) ->
    if @_midi
      input = @_getInputKeyAtIndex(index, @_midi.inputs.entries())
      return input.name

  closePort: ->
    if @_port
      @_port.close()

  openPort: (i) ->
    @_doOpenPort(i)

  openVirtualPort: (i) ->
    @_doOpenPort(i)

  on: (event, cb) ->
    switch event
      when 'message'
        @_listeners.push cb

    return false

class MidiOutput
  closePort: -> {}
  openPort: -> {}
  openVirtualPort: -> {}
  sendMessage: -> {}
  getPortCount: -> 0
  getPortName: -> {}

@input = MidiInput
@output = MidiOutput

