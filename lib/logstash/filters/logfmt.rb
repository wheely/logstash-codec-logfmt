require 'logstash/filters/base'
require 'logstash/namespace'
require 'logfmt'
require 'json'

# Add any asciidoc formatted documentation here
class LogStash::Filters::Logfmt < LogStash::Filters::Base
  config_name 'logfmt'

  # The source field to parse
  config :source, validate: :string

  # The target field to place all the data
  config :target, validate: :string, default: 'logfmt'

  # Remove source
  config :remove_source, validate: :boolean, default: false

  # Convert fields to json
  config :convert_to_json, validate: :array, default: []

  # Convert fields to strings
  config :convert_to_string, validate: :array, default: []

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
    for k,v in params do
      params.delete(k) if v == true 
    end

    event.set(@target, process_hash(params))
    event.set(@source, nil) if @remove_source
    return true
  rescue => e
    log_exception(e, data)
    nil
  end

  private

  def log_exception(e, data)
    @logger.error({
      msg: 'Failed to parse logfmt string',
      error: {
        message: e.message,
        err: e.class.to_s,
        data: data,
        stacktrace: (e.backtrace && e.backtrace.join(','))
      }
    }.to_json)
  end

  def process_hash(hash)
    hash.each_with_object({}) do |(key,value), all|
      key_parts = key.split('.')
      leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {} }
      leaf[key_parts.last] = value
    end.each_with_object({}) do |(key,value), all|
      next all[key] = value.to_json if @convert_to_json.include?(key)
      next all[key] = value.to_s if @convert_to_string.include?(key)
      all[key] = value
    end
  end
end # class LogStash::Filters::Logfmt
