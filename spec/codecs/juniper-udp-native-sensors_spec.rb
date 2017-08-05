# encoding: utf-8
require_relative '../spec_helper'
require_relative '../../lib/telemetry_top.pb'
require "logstash/codecs/proto_lib/juniper_telemetry_lib.rb"
require "logstash/codecs/juniper-udp-native-sensors"
require 'logstash/event'
require 'json'
require 'socket'

describe LogStash::Codecs::JuniperUdpNativeSensors do
    context "Testing decode method" do
        #let (:config) {{:a => 1}}
        let (:jti_msg) {double()}
        let (:enterp) {double()}
        let (:jnprnet) {double()}
        let (:epoc_to_sec) {double("epoc_to_sec")}
        let (:jnpr_sensor) {double()}
        
        subject do
            next LogStash::Codecs::JuniperUdpNativeSensors.new
        end
        
        context "Testing decode" do
            it "Checking event type" do
                allow(epoc_to_sec).to receive(:epoc).and_return("12345678")
                json_txt = {"jnpr_interface_ext": {"interface_stats": [{"name":"Kernel"}, {"name":"RE"}]}}
                enterp.stub(:juniperNetworks) {jnpr_sensor}
                jnpr_sensor.stub(:to_json) {json_txt}
                jti_msg.stub(:system_id) {'DEVICE-A'}
                jti_msg.stub(:timestamp) {'1234567890909'}
                jti_msg.stub(:enterprise) {enterp}
                TelemetryStream.any_instance.stub(:decode).and_return(jti_msg)
                enterp.stub(:juniperNetworks) {json_txt}
                
                subject.decode("test") do |event|
                    insist {event.is_a? LogStash::Event}
                end
            end
            it "Checking the values" do
                allow(epoc_to_sec).to receive(:epoc).and_return("12345678")
                json_txt = {"jnpr_interface_ext": {"interface_stats": [{"name":"Kernel"}, {"name":"RE"}]}}
                enterp.stub(:juniperNetworks) {jnpr_sensor}
                jnpr_sensor.stub(:to_json) {json_txt}
                jti_msg.stub(:system_id) {'DEVICE-A'}
                jti_msg.stub(:timestamp) {'1234567890909'}
                jti_msg.stub(:enterprise) {enterp}
                TelemetryStream.any_instance.stub(:decode).and_return(jti_msg)
                enterp.stub(:juniperNetworks) {json_txt}
                
                result = [{"interface_stats.name"=>"Kernel", "device"=>"DEVICE-A", "host"=>"choc-esxi6-a-vm4", "sensor_name"=>"juniperNetworks.jnpr_interface_ext", "time"=>1234567890}, 
                          {"interface_stats.name"=>"RE", "device"=>"DEVICE-A", "host"=>"choc-esxi6-a-vm4", "sensor_name"=>"juniperNetworks.jnpr_interface_ext", "time"=>1234567890}  ]
                count = 0
                subject.decode("test") do |event|
                    case count
                        when 0
                            expect(event.get("interface_stats.name")).to eq("Kernel")
                            expect(event.get("device")).to eq("DEVICE-A")
                            expect(event.get("host")).to eq(Socket.gethostname)
                            expect(event.get("sensor_name")).to eq("juniperNetworks.jnpr_interface_ext")
                            expect(event.get("time")).to eq(1234567890)
                        when 1
                            expect(event.get("interface_stats.name")).to eq("RE")
                            expect(event.get("device")).to eq("DEVICE-A")
                            expect(event.get("host")).to eq(Socket.gethostname)
                            expect(event.get("sensor_name")).to eq("juniperNetworks.jnpr_interface_ext")
                            expect(event.get("time")).to eq(1234567890)
                    end
                    count += 1
                end
            end
        end
    end
end

