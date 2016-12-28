# encoding: utf-8
require 'logstash/codecs/base'
require 'logstash/event'
require 'logfmt'

# Add any asciidoc formatted documentation here
class LogStash::Codecs::Logfmt < LogStash::Codecs::Base
  config_name 'logfmt'

  def register
  end

  def decode(data)
    puts "Got data to decode: #{data.inspect}"
    event = Logfmt.parse(data)
    if !event['level'].is_a?(String) || event['level'].empty?
      event = { 'tags' => ['_logfmtparsefailure'] }
    end
    if event['stacktrace']
      if event['stacktrace'].start_with?('[')
        event['stacktrace'] = event['stacktrace'][1..-2].split('][')
      else
        event['stacktrace'] = event['stacktrace'].split(',')
      end
    end
    event['message'] = data
    yield LogStash::Event.new(event)
  end # def decode
end # class LogStash::Codecs::Logfmt
