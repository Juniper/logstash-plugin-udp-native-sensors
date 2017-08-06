# Logstash Juniper telemetry plugin for native sensors on UDP

Juniper devices can send telemetry over UDP with protobuf encoding.
This plugin can parse the protobuf messages so that senesor data can be stored.

Supported pipeline for this use cases UDP -> Juniper UDP/native sensor codec -> influxdb

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
    }
}
```
