'use strict'

router = require( './router' ).router
utils = require( './utils' ).utils
legatoMidi = require './midi'
midi = require './browser-midi'
# midi = require 'midi'
midiHelp = require 'midi-help'
omgosc = require 'omgosc'
legatoOSC = require './osc'
_ = require 'lodash'

utils.inject _
router.inject utils
legatoMidi.inject router, utils, midi, midiHelp
legatoOSC.inject utils, omgosc

@midi = legatoMidi
@osc = legatoOSC
# TODO Provide access to firmata and amixer

# TODO Pass in config that defines which libraries
# the user wants to utilize.
@init = ->
  router.init()

@in = (prefix, input) ->
  return router.in prefix, input

@on = (path, callback) ->
  return router.on path, callback

@removeRoute = (id) ->
  router.removeRoute id

@removeInput = (id, prefix) ->
  router.removeInput id, prefix

@deinit = ->
  router.deinit()

