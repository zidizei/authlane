require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane::Helpers do
  before :all do
    mock_app do
      helpers Sinatra::Cookies
      register Sinatra::AuthLane

      use Rack::Session::Cookie, :secret => 'rspec'

      Sinatra::AuthLane.create_auth_strategy { { id: 1 } }

      get '/protected' do
        protect!
      end

      get '/authorized' do
        if authorized?
          'authorized'
        else
          'unauthorized'
        end
      end

      get '/authorize' do
        authorize!
        protect!
      end

      get '/unauthorize' do
        unauthorize!
        protect!
      end

      get '/user' do
        protect!
        user = current_user
        user
      end
    end
  end

  it "should be able to recognize authorized states" do
    get '/authorized', {}, { 'rack.session' => { authlane: { id: 1 } } }
    expect(last_response.body).to eq('authorized')
  end

  it "should be able to recognize unauthorized states" do
    get '/authorized'
    expect(last_response.body).to eq('unauthorized')
  end

  it "should redirect from protected route to signin page when not logged in" do
    get '/protected'
    expect(last_response.headers['location']).to eq('http://example.org/user/unauthorized')
  end

  it "should display protected route when logged in" do
    get '/protected', {}, { 'rack.session' => { authlane: '1' } }
    last_response.should be_ok
  end

  it "should authorize a User" do
    get '/authorize'
    last_response.should be_ok
  end

  it "should unauthorize a User" do
    get '/unauthorize', {}, { 'rack.session' => { authlane: '1' } }
    expect(last_response.headers['location']).to eq('http://example.org/user/unauthorized')
  end

  it "should be able to get the current User's serialized credentials" do
    get '/user', {}, { 'rack.session' => { authlane: '1' } }
    expect(last_response.body).to eq('1')
  end
end
