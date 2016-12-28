# encoding: utf-8
require 'logstash/codecs/base'
require 'logstash/event'
require 'logfmt'

# Add any asciidoc formatted documentation here
class LogStash::Codecs::Logfmt < LogStash::Codecs::Base
  config_name 'logfmt'

  config :charset, validate: ::Encoding.name_list, default: 'UTF-8'

  def register
  end

  def decode(data)
    event = Logfmt.parse(data)
    if !event['level'].is_a?(String) || event['level'].empty?
      event = { '_logfmtparsefailure' => true }
    end
    event['message'] = data
    yield LogStash::Event.new(event)
  end # def decode
end # class LogStash::Codecs::Logfmt
