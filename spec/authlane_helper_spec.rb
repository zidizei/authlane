require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane::Helpers do
  before :all do
    build_rack_test_session 'rspec'

    mock_app do
      helpers Sinatra::Cookies
      register Sinatra::AuthLane

      use Rack::Session::Cookie, :secret => 'rspec'

      set :authlane, :serialize_user => [:id, :rank]

      Sinatra::AuthLane.create_auth_strategy do
        cookies[:'authlane.token'] = 'rspec'
        { id: '1', rank: 1 }
      end

      Sinatra::AuthLane.create_role_strategy do |ranks|
        current_user[:rank] == ((ranks.nil?) ? 1 : ranks)
      end

      Sinatra::AuthLane.create_role_strategy(:roles2) do |ranks|
        current_user[:rank] == ((ranks.nil?) ? 2 : ranks)
      end

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

      get '/role1' do
        protect! :roles
      end

      get '/role1a' do
        protect! :roles => 2
      end

      get '/role2' do
        protect! :roles2
      end

      get '/role2a' do
        protect! :roles2 => 1
      end

      get '/unauthorize' do
        unauthorize!
        protect!
      end

      get '/user' do
        protect!
        user = current_user
        user[:id]
      end
    end
  end

  before :each do
    clear_cookies
  end


  it "should authorize a User" do
    get '/authorize'
    last_response.should be_ok
  end

  it "should remember a User by setting the token cookie" do
    expect(rack_mock_session.cookie_jar['authlane.token']).to be(nil)
    get '/authorize'
    expect(rack_mock_session.cookie_jar['authlane.token']).to eq('rspec')
  end

  it "should be able to recognize authorized states" do
    get '/authorize'
    get '/authorized'
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

  it "should show protected route when logged in" do
    get '/authorize'
    get '/protected'
    last_response.should be_ok
  end

  it "should unauthorize a User" do
    get '/authorize'
    get '/authorized'
    expect(last_response.body).to eq('authorized')
    get '/unauthorize'
    expect(last_response.headers['location']).to eq('http://example.org/user/unauthorized')
    get '/authorized'
    expect(last_response.body).to eq('unauthorized')
  end

  it "should forget a User's remember token" do
    get '/authorize'
    expect(rack_mock_session.cookie_jar['authlane.token']).to eq('rspec')

    get '/unauthorize'
    expect(rack_mock_session.cookie_jar['authlane.token']).to eq('')
  end

  it "should be able to get the current User's serialized credentials" do
    get '/authorize'
    get '/user'#, {}, { 'rack.session' => { authlane: '1' } }
    expect(last_response.body).to eq('1')
  end

  it "should be able to use role strategy" do
    get '/authorize'
    get '/role1'
    last_response.should be_ok
  end

  it "should be able to use role strategy with arguments" do
    get '/authorize'
    get '/role1a'
    expect(last_response.headers['location']).to eq('http://example.org/user/unauthorized')
  end

  it "should be able to use named role strategy" do
    get '/authorize'
    get '/role2'
    expect(last_response.headers['location']).to eq('http://example.org/user/unauthorized')
  end

  it "should be able to use named role strategy with arguments" do
    get '/authorize'
    get '/role2a'
    last_response.should be_ok
  end
end
