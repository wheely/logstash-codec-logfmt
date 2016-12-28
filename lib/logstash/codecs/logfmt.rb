# encoding: utf-8
require 'logstash/codecs/base'
require 'logstash/util/charset'
require 'logstash/event'
require 'logfmt'

# Add any asciidoc formatted documentation here
class LogStash::Codecs::Logfmt < LogStash::Codecs::Base
  config_name 'logfmt'

  config :charset, validate: ::Encoding.name_list, default: 'UTF-8'

  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
    @logger.info 'Logfmt codec regidtered'
  end

  def decode(data)
    @logger.info "Got data to decode: #{data.inspect}"
    data = @converter.convert(data)
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
  rescue => e
    logger.error(e)
  end # def decode
end # class LogStash::Codecs::Logfmt
