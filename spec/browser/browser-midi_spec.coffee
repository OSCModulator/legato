'use strict'

describe 'browser-midi', ->
  beforeEach ->
    console.info = ->
    return

  describe 'using the real MIDI input implementation', ->
    input = null

    beforeEach ->
      input = new LegatoMidiInput()

    it 'should be able to create an input object.', ->
      expect(input).toBeDefined()

    it 'should be able to get the number of available ports.', ->
      expect( -> input.getPortCount() ).not.toThrow()
      expect( input.getPortCount() ).toBe(0)

    it 'should be able to get a promise for when midi becomes available.', ->
      expect( input.ready() ).toEqual(jasmine.any(Promise))

    it 'should resolve the ready promise when midi becomes available.', (done) ->
      input.ready().then (hasMidi) ->
        expect(hasMidi).toBe(true)
        done()
      .catch (e) ->
        expect(e).toBe(false)
        done()

  describe 'using the real MIDI output implementation', ->
    output = null

    beforeEach ->
      output = new LegatoMidiOutput()

    it 'should be able to create an output object.', ->
      expect(output).toBeDefined()

    it 'should be able to get the number of available ports.', ->
      expect( -> output.getPortCount() ).not.toThrow()
      expect( output.getPortCount() ).toBe(0)

    it 'should be able to get a promise for when midi becomes available.', ->
      expect( output.ready() ).toEqual(jasmine.any(Promise))

    it 'should resolve the ready promise when midi becomes available.', (done) ->
      output.ready().then (hasMidi) ->
        expect(hasMidi).toBe(true)
        done()
      .catch (e) ->
        expect(e).toBe(false)
        done()

