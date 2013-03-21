# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/flasher/version'

Gem::Specification.new do |gem|
  gem.name          = "rack-flasher"
  gem.version       = Rack::Flasher::VERSION
  gem.authors       = ["Iain Barnett"]
  gem.email         = ["iainspeed@gmail.com"]
  gem.description   = %q{Rack Flash meets Sinatra Flash, in Rack}
  gem.summary       = %q{Rack middleware}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency("rack")
end
