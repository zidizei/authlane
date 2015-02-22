require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane::SerializedUser do
  class MockUser
    def id
      1
    end

    def name
      'rspec'
    end
  end

  it 'can be accessed like a Hash' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' })
    user.should respond_to(:[])
    user[:id].should eql(1)
    user[:name].should eql('rspec')
  end

  it 'can be accessed like an Object' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' })
    user.should respond_to(:method_missing)
    user.id.should eql(1)
    user.name.should eql('rspec')
  end

  it 'should return Hash of the serialized User object' do
    user = Sinatra::AuthLane::SerializedUser.new(MockUser.new)
    user.to_h.should be_a(Hash)
  end

  it 'should return Hash of the serialized User object with String keys' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' }).to_h
    user['id'].should eql(1)
    user['name'].should eql('rspec')
  end

  it 'should return Hash of the serialized User object with Symbol keys' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' }).to_h
    user[:id].should eql(1)
    user[:name].should eql('rspec')
  end

  it 'can serialize specific attribute names from a Hash' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: 'rspec' }, [:id])
    user[:id].should eql(1)
    user[:name].should be(nil)
  end

  it 'can serialize specific attribute names from an Object' do
    user = Sinatra::AuthLane::SerializedUser.new(MockUser.new, [:id])
    user[:id].should eql(1)
    user[:name].should be(nil)
  end

  it 'can change specific attributes after initialization from an Object' do
    user = Sinatra::AuthLane::SerializedUser.new(MockUser.new, [:id])
    user[:id].should eql(1)
    user[:name].should be(nil)
    user[:name] = 'Rspec'
    user[:name].should eql('Rspec')
  end

  it 'can change specific attributes after initialization from a Hash' do
    user = Sinatra::AuthLane::SerializedUser.new({ id: 1, name: nil }, [:id])
    user[:id].should eql(1)
    user[:name].should be(nil)
    user[:name] = 'Rspec'
    user[:name].should eql('Rspec')
  end

  it 'can not change id attribute after initialization' do
    user = Sinatra::AuthLane::SerializedUser.new(MockUser.new, [:id])
    user[:id].should eql(1)
    user[:id] = 2
    user[:id].should eql(1)
  end
end
