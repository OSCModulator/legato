'use strict'

sandbox = require('./utils').sandbox
_ = require('lodash')

describe 'legato.http', ->
  beforeEach ->
    genericGlobals =
      console: console

    utils = sandbox('lib/utils.coffee', genericGlobals).utils
    utils.inject _

    @request = jasmine.createSpy('httpRequestSpy')

    @http = sandbox('lib/http.coffee', genericGlobals)
    @http.inject(utils, @request)


  xit 'should log with its prefix.', ->
    expect(true).toBe(true)

  describe 'after asking for an HTTP sender', ->
    beforeEach ->
      @host = 'localhost'
      @port = '8000'
      @baseUrl = "http://#{@host}:#{@port}"
      @sender = @http.Out(@host, @port)

    it 'should return a sender function.', ->
      expect(@sender).toEqual(jasmine.any(Function))

    it 'should be able to GET over http.', ->
      path = '/this/path'
      @sender(path)
      expect(@request).toHaveBeenCalledWith({
        uri: path,
        baseUrl: @baseUrl,
        method:'GET',
        body:''
      }, jasmine.any(Function))

    it 'should be able to POST over http.', ->
      path = '/that/path'
      method = 'POST'
      body = 'this body, that body'
      @sender(path, body, method)
      expect(@request).toHaveBeenCalledWith({
        uri:path
        baseUrl: @baseUrl
        method:method
        body:body
      }, jasmine.any(Function))

    xit 'should be able to PUT over http.'
    xit 'should be able to DELETE over http.'

  xit 'should be able to make HTTPS requests.'


