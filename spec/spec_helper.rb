ENV['RACK_ENV'] = 'test'

require 'sinatra/test_helpers'
require 'sinatra/cookies'

require 'sinatra/authlane'

RSpec.configure do |c|
  c.include Sinatra::TestHelpers
  c.include Rack::Test::Methods
end
