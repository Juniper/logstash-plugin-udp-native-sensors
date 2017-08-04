Gem::Specification.new do |s|
  s.name          = 'logstash-codec-juniper-udp-native-sensors'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Input plugin for Logstash for Juniper devices telemetry data streaming native sensor data in UDP'
  s.description   = 'Input plugin for Fluentd for Juniper devices telemetry data streaming native sensor data in UDP'
  s.homepage      = 'http://github.com'
  s.authors       = ['Vijay Kumar gadde']
  s.email         = ["vijaygadde@gmail.com"]
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "codec" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', "~> 2.0"
  s.add_runtime_dependency 'logstash-codec-line'
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'protobuf'
end
