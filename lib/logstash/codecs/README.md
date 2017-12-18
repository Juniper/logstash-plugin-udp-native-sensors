# Logstash Juniper telemetry plugin for native sensors on UDP

This plugin is designed to parse the Juniper Native sensors data.
Juniper Native sensor data are Google Protobuf messages sent over UDP. Hence this plugin should be used with UDP input plugin.

Below are few points that are considered:

* No sessions are maintained to the devices
* Existing UDP listener input plugin should be used to listen on configured ports
* Data from UDP listener will be passed to the parser plugin that is written in here
* In case of changes to sensor definition, the proto files have to be recompiled to appropriate library based on the collector and added to the plugin repository
* In case of addition of new sensor, corresponding proto files need to be compiled to appropriate library and should be added to the plugin repository
* Timestamp, system_id from the JTI message and hostname on which the collector is running is added to all the entries

Below is can example configuration.

```sh
input {
    udp {
        port => 50000
        codec => juniper-udp-native-sensors {
        }
    }
}
output {
    influxdb {
        db => logstash
        host => localhost
        port => 8086
        user => juniper
        password => juniper
        allow_time_override => true
        use_event_fields_for_data_points => true
        measurement => "%{sensor_name}"
        "time_precision" => "s"
        flush_size => 1
        send_as_tags => ["host", "device", "_seq", "__local_time__"]
    }
}
```
