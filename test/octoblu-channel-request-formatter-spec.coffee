ReturnValue = require 'nanocyte-component-return-value'
OctobluChannelRequestFormatter = require '../src/octoblu-channel-request-formatter'

describe 'OctobluChannelRequestFormatter', ->
  beforeEach ->
    @sut = new OctobluChannelRequestFormatter

  it 'should exist', ->
    expect(@sut).to.be.an.instanceOf ReturnValue

  describe '->onEnvelope', ->
    describe 'when called with an envelope', ->
      it 'should return the message', ->
        expect(@sut.onEnvelope({message: 'anything'})).to.deep.equal 'anything'
