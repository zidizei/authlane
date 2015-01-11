require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane::SerializedUser do
  def mock_user
    Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' })
  end

  it 'can be accessed like a Hash' do
    user = mock_user
    user.should respond_to(:[])
    user[:id].should eql(1)
    user[:name].should eql('rspec')
  end

  it 'can be accessed like an Object' do
    user = mock_user
    user.should respond_to(:method_missing)
    user.id.should eql(1)
    user.name.should eql('rspec')
  end

  it 'should return Hash of the serialized User object' do
    user = mock_user
    user.to_h.should be_a(Hash)
  end

  it 'should return Hash of the serialized User object with String keys' do
    user = mock_user.to_h
    user['id'].should eql(1)
    user['name'].should eql('rspec')
  end

  it 'should return Hash of the serialized User object with Symbol keys' do
    user = mock_user.to_h
    user[:id].should eql(1)
    user[:name].should eql('rspec')
  end
end
