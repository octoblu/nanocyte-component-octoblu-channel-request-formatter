ReturnValue = require 'nanocyte-component-return-value'

class OctobluChannelRequestFormatter extends ReturnValue
  onEnvelope: (envelope) =>
    return envelope.message

module.exports = OctobluChannelRequestFormatter
