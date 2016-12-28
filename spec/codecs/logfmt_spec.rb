require 'logstash/devutils/rspec/spec_helper'
require 'logstash/codecs/logfmt'
require 'logstash/event'
require 'logstash/json'
require 'insist'

describe LogStash::Codecs::Logfmt do
  subject do
    next LogStash::Codecs::Logfmt.new
  end

  context '#decode' do
    let(:data) { %(time=2016-12-27T16:15:00.108+00:00 level=error response_status=401 response_body.error="Your user ID or license key could not be authenticated." msg="too many connection resets (due to Net::ReadTimeout - Net::ReadTimeout) after 89 requests on 47144016160240, last used 97.457622864 seconds ago" logger=Wheely::App::Pusher::SmsTransport::Devino err=Net::HTTP::Persistent::Error phone=+79263030599 body="4474 - \u0432\u0430\u0448 \u043A\u043E\u0434" thread=47144031566240 stacktrace="[/usr/local/lib/ruby/2.2.0/net/protocol.rb:158:rescue in rbuf_fill][/usr/local/lib/ruby/2.2.0/net/protocol.rb:152:rbuf_fill][/usr/local/lib/ruby/2.2.0/net/protocol.rb:134:readuntil][/usr/local/lib/ruby/2.2.0/net/protocol.rb:144:readline][/usr/local/lib/ruby/2.2.0/net/http/response.rb:39:read_status_line][/usr/local/lib/ruby/2.2.0/net/http/response.rb:28:read_new][/usr/local/bundle/gems/aws-sdk-core-2.3.0/lib/seahorse/client/net_http/patches.rb:29:block in new_transport_request][/usr/local/bundle/gems/aws-sdk-core-2.3.0/lib/seahorse/client/net_http/patches.rb:26:catch][/usr/local/bundle/gems/aws-sdk-core-2.3.0/lib/seahorse/client/net_http/patches.rb:26:new_transport_request][/usr/local/lib/ruby/2.2.0/net/http.rb:1384:request][/usr/local/bundle/gems/net-http-persistent-2.9.4/lib/net/http/persistent.rb:999:request][/app/lib/sms_transport/devino.rb:45:send_message][/app/lib/sms_transport/devino.rb:22:delivery][/app/lib/sms_transport.rb:48:block (2 levels) in delivery_message][/app/lib/common/statsd.rb:63:call][/app/lib/common/statsd.rb:63:block in delivery_time][/usr/local/bundle/gems/dogstatsd-ruby-1.6.0/lib/statsd.rb:199:time][/app/lib/common/statsd.rb:63:delivery_time][/app/lib/sms_transport.rb:48:block in delivery_message][/app/lib/sms_transport.rb:46:each][/app/lib/sms_transport.rb:46:find][/app/lib/sms_transport.rb:46:delivery_message][/app/lib/sms_transport.rb:28:delivery][/app/lib/tasks/delivery_sms_task.rb:22:block in delivery][/usr/local/bundle/gems/logfoo-0.1.4/lib/logfoo/context.rb:33:context][/app/lib/tasks/delivery_sms_task.rb:16:delivery][/app/lib/consumers/notifications_consumer.rb:40:process][/usr/local/bundle/gems/hutch-0.21.0/lib/hutch/tracers/null_tracer.rb:10:handle][/usr/local/bundle/gems/hutch-0.21.0/lib/hutch/worker.rb:119:handle_message][/usr/local/bundle/gems/hutch-0.21.0/lib/hutch/worker.rb:101:block in setup_queue][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer.rb:56:call][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer.rb:56:call][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/channel.rb:1721:block in handle_frameset][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:97:call][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:97:block (2 levels) in run_loop][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:92:loop][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:92:block in run_loop][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:91:catch][/usr/local/bundle/gems/bunny-2.3.1/lib/bunny/consumer_work_pool.rb:91:run_loop]") }
    it 'should decode valid logfmt data' do
      subject.decode(data) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event.get('time') } == '2016-12-27T16:15:00.108+00:00'
        insist { event.get('level') } == 'error'
        insist { event.get('response_status') } == 401
        insist { event.get('response_body.error') } == 'Your user ID or license key could not be authenticated.'
        insist { event.get('stacktrace').is_a? Array }
      end
    end
    it 'should be fast', performance: true do
      iterations = 5_000
      count = 0
      # Warmup
      10_000.times { subject.decode(data) {} }
      start = Time.now
      iterations.times do
        subject.decode(data) do |_event|
          count += 1
        end
      end
      duration = Time.now - start
      insist { count } == iterations
      puts "codecs/logfmt rate: #{'%02.0f/sec' % (iterations / duration)}, elapsed: #{duration}s"
    end
    context 'processing plain text' do
      let(:data) { "something containing level word that isn't json" }
      it 'falls back to plain text' do
        decoded = false
        subject.decode(data) do |event|
          decoded = true
          insist { event.is_a?(LogStash::Event) }
          insist { event.get('message') } == data
          insist { event.get('tags').include?('_logfmtparsefailure') }
        end
        insist { decoded } == true
      end
      it "falls back to plain text and doesn't crash (LOGSTASH-1595)" do
        blob = (128..255).to_a.pack('C*').force_encoding('ASCII-8BIT')
        subject.decode(blob) do |event|
          insist { event.is_a?(LogStash::Event) }
        end
      end
    end
  end
end
