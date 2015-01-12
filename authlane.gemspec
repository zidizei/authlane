# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'authlane/version'

Gem::Specification.new do |spec|
  spec.name          = 'authlane'
  spec.version       = Authlane::VERSION
  spec.authors       = ['Patrick Lam']
  spec.email         = ['zidizei@gmail.com']
  spec.summary       = 'Simple User authentication and roles for Sinatra.'
  spec.description   = <<-EOF
    The AuthLane Sinatra Extension allows simple User authentication with support
    for different User roles. It comes with Sinatra helpers for easy integration into routes.
  EOF
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-contrib'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'rspec', '~> 2.6'
  spec.add_development_dependency 'yard', '~> 0.8'
end
