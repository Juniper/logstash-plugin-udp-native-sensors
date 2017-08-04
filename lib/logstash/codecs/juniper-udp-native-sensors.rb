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
        require "logstash/codecs/proto_lib/juniper_telemetry_lib.rb"
        require "logstash/codecs/proto_lib/port.pb.rb"
        require "logstash/codecs/proto_lib/lsp_stats.pb.rb"
            require "logstash/codecs/proto_lib/logical_port.pb.rb"
        require "logstash/codecs/proto_lib/firewall.pb.rb" 
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
        
        for record in final_data
            record['device'] = device_name
            record['host'] = host
            record['sensor_name'] = "juniperNetworks" + "." + datas_sensors.keys[0]
            record['time'] = gpb_time
            yield LogStash::Event.new(record)
        end
        
    end # def decode
    
    # Encode a single event, this returns the raw data to be returned as a String
    def encode_sync(event)
        event.get("message").to_s + @append + NL
    end # def encode_sync
    
    private
    def parse_hash(data, jnpr_sensor, master_key='')
        leaf_data = Hash.new
        arr_data = Array.new
        arr_key = Array.new
        fin_data = Array.new
        data.each do |key, value|
            if master_key == ''
                new_master_key = key
            else
                new_master_key = master_key + '.' + key
            end

            if not [Hash, Array].include?(value.class)
                leaf_data[new_master_key] = value
            elsif value.is_a? Array
                arr_data << parse_array(value, jnpr_sensor, new_master_key)
                arr_key <<  new_master_key
            elsif value.is_a? Hash
                arr_data << parse_hash(value, jnpr_sensor, new_master_key)
                arr_key << new_master_key
            end
        end
        # Put all the data from Array to hash.
        # If the key names with list name to avoid overwriting
        if not leaf_data.empty?
            arr_key.length.times do |i|
                for data_aa in arr_data[i]
                    leaf_tmp = leaf_data.clone
                    if not data_aa == nil
                        data_aa.each do |key_aa, value_aa|
                            leaf_tmp[key_aa] = value_aa
                        end
                    end
                    fin_data += [leaf_tmp]
                end
            end
        else
            fin_data = arr_data.clone
        end
        arr_data.clear
        
        if (fin_data.to_a.empty?) && (not leaf_data.empty?)
            fin_data += [leaf_data]
        end
        
        return fin_data
      end

      def parse_array(data, jnpr_sensor, master_key)
        
        arr_data = []
        for value in data
            if value.is_a? Hash
                arr_data += parse_hash(value, jnpr_sensor, master_key)
            else
                $log.error "Leaf elements in array are not coded. Please open a issue."
            end
        end
        
        return arr_data

      end

end # class LogStash::Codecs::JuniperUdpNativeSensors
