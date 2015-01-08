# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'authlane/version'

Gem::Specification.new do |spec|
  spec.name          = 'authlane'
  spec.version       = Authlane::VERSION
  spec.authors       = ['Patrick Lam']
  spec.email         = ['zidizei@gmail.com']
  spec.summary       = 'Easy User authentication and roles for Sinatra.'
  spec.description   = 'The AuthLane Sinatra Extension allows easy User authentication with support for different User roles.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-contrib'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'rspec', '~> 2.6'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'yard-sinatra'
end
