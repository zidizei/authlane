require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane do
  class Serialized
    attr_reader :id

    def initialize(user)
      serialize(user)
    end

    def serialize(user)
      @id = user[:id]
    end
  end

  before :all do
    build_rack_test_session 'rspec'

    mock_app do
      helpers Sinatra::Cookies
      register Sinatra::AuthLane

      use Rack::Session::Cookie, :secret => 'rspec'

      set :authlane, serialize_user: Serialized

      Sinatra::AuthLane.create_auth_strategy do
        cookies[:'authlane.token'] = 'rspec'
        { id: '1', name: 'rspec' }
      end

      get '/authorize' do
        authorize!
        protect!
      end
    end
  end

  before :each do
    clear_cookies
  end

  def current_user
    Marshal.load(rack_mock_session.cookie_jar['rack.session'].unpack('m*').first)
  end

  it 'uses custom SerializedUser class instead of the built-in one when specified' do
    get '/authorize'
    last_response.should be_ok
    expect(current_user['authlane']).to be_a Serialized
  end
end
