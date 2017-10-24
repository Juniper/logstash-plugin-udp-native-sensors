# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "logstash/namespace"
require 'protobuf'
require 'json'
require "socket"

# This  codec will append a string to the message field
# of an event, either in the decoding or encoding methods
#
# This is only intended to be used as an example.
#
# input {
#   stdin { codec =>  }
# }
#
# or
#
# output {
#   stdout { codec =>  }
# }
#
class LogStash::Codecs::JuniperUdpNativeSensors < LogStash::Codecs::Base
    
    # The codec name
    config_name "juniper-udp-native-sensors"
    
    # Append a string to the message
    config :append, :validate => :string, :default => ', Hello World!'
    
    def register
        require "logstash/codecs/proto_lib/cpu_memory_utilization.pb.rb"
        require "logstash/codecs/proto_lib/juniper_telemetry_udp_lib.rb"
        require "logstash/codecs/proto_lib/port.pb.rb"
        require "logstash/codecs/proto_lib/lsp_stats.pb.rb"
        require "logstash/codecs/proto_lib/logical_port.pb.rb"
        require "logstash/codecs/proto_lib/firewall.pb.rb" 
        require "logstash/codecs/proto_lib/qmon.pb.rb"
        require "logstash/codecs/proto_lib/cmerror.pb.rb"
        require "logstash/codecs/proto_lib/cmerror_data.pb.rb"
        require "logstash/codecs/proto_lib/fabric.pb.rb"
        require "logstash/codecs/proto_lib/inline_jflow.pb.rb"
        require "logstash/codecs/proto_lib/lsp_mon.pb.rb"
        require "logstash/codecs/proto_lib/npu_utilization.pb.rb"
        require "logstash/codecs/proto_lib/npu_memory_utilization.pb.rb"
        require "logstash/codecs/proto_lib/port_exp.pb.rb"
        require "logstash/codecs/proto_lib/packet_stats.pb.rb"
        require "logstash/codecs/proto_lib/optics.pb.rb"
        @lines = LogStash::Codecs::Line.new
        @lines.charset = "UTF-8"
    end # def register
    
    def decode(data)
        host = Socket.gethostname
        
        ## Decode GBP packet
        jti_msg =  TelemetryStream.decode(data)
        
        ## Extract device name & Timestamp
        device_name = jti_msg.system_id
        puts device_name
        
        gpb_time = epoc_to_sec(jti_msg.timestamp)
        local_time = Time.now.to_f
        measurement_prefix = "enterprise.juniperNetworks"
        
        # Extract sensor
        begin
            jnpr_sensor = jti_msg.enterprise.juniperNetworks
            datas_sensors = JSON.parse(jnpr_sensor.to_json)
            logger.debug "#{datas_sensors}"
            logger.debug "Extract sensor data from #{device_name}"
        rescue => e
            logger.warn "Unable to extract sensor data sensor from jti_msg.enterprise.juniperNetworks, Error during processing: #{$!}"
            logger.debug  "Unable to extract sensor data sensor from jti_msg.enterprise.juniperNetworks, Data Dump : " + jti_msg.inspect.to_s
        end
        
        ## Go over each Sensor
        final_data = Array.new
        datas_sensors.each do |sensor, s_data|
            if s_data.is_a? Hash
                final_data = parse_hash(s_data, jnpr_sensor)[0]
            end
        end
        
        seq = 0
        for record in final_data
            seq = seq + 1
            record['device'] = device_name
            record['host'] = host
            record['sensor_name'] = "juniperNetworks" + "." + datas_sensors.keys[0]
            record['time'] = gpb_time
            record['_seq'] = seq
            record['__local_time__'] = local_time
            yield LogStash::Event.new(record)
        end
        
    end # def decode
    
    # Encode a single event, this returns the raw data to be returned as a String
    def encode_sync(event)
        event.get("message").to_s + @append + NL
    end # def encode_sync
    
end # class LogStash::Codecs::JuniperUdpNativeSensors
