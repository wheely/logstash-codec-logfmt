# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'
require 'logfmt'

# Add any asciidoc formatted documentation here
class LogStash::Filters::Logfmt < LogStash::Filters::Base
  config_name 'logfmt'

  # The source field to parse
  config :source, validate: :string

  # The target field to place all the data
  config :target, validate: :string, default: 'logfmt'

  def register
    @logger.info 'Logfmt filter registered'
  end

  def filter(event)
    return if resolve(event).nil?
    filter_matched(event)
  end

  def resolve(event)
    data = event.get(@source)
    params = Logfmt.parse(data)

    # log line should at least have level
    return if !params['level'].is_a?(String) || params['level'].empty?

    if params['stacktrace']
      if params['stacktrace'].start_with?('[')
        params['stacktrace'] = params['stacktrace'][1..-2].split('][')
      else
        params['stacktrace'] = params['stacktrace'].split(',')
      end
    end
    event.set(@target, params)
    true
  rescue => e
    @logger.error "Failed to parse data: #{data}"
    @logger.error e
  end
end # class LogStash::Filters::Logfmt
