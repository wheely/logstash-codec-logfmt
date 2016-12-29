# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'
require 'logfmt'
require 'json'
require_relative 'logfmt_patch'

# Add any asciidoc formatted documentation here
class LogStash::Filters::Logfmt < LogStash::Filters::Base
  config_name 'logfmt'

  # The source field to parse
  config :source, validate: :string

  # The target field to place all the data
  config :target, validate: :string, default: 'logfmt'

  # Remove source
  config :remove_source, validate: :boolean, default: false

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
    event.set(@target, flat_keys_to_nested(params))
    event.set(@source, nil) if @remove_source
    return true
  rescue => e
    log_exception(e)
    nil
  end

  private

  def log_exception(e)
    @logger.error({
      msg: 'Failed to parse logfmt string',
      error: {
        message: e.message,
        err: e.class.to_s,
        data: data,
        stacktrace: (e.backtrace && e.backtrace.join(','))
      }.compact
    }.to_json)
  end

  def flat_keys_to_nested(hash)
    hash.each_with_object({}) do |(key,value), all|
      key_parts = key.split('.').map!(&:to_sym)
      leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {} }
      leaf[key_parts.last] = value.to_s
    end
  end
end # class LogStash::Filters::Logfmt
