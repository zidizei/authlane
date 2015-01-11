require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane do
  def strategy(type, &block)
    mock_app do
      register Sinatra::AuthLane

      Sinatra::AuthLane.send "create_#{type}_strategy", &block
    end
  end

  it "should allow definition of auth strategy" do
    strategy(:auth) do
      'rspec'
    end

    settings.authlane[:auth_strategy].yield.should == 'rspec'
  end

  it "should allow definition of role strategy" do
    strategy(:role) do
      'rspec'
    end

    settings.authlane[:role_strategy].yield.should == 'rspec'
  end

  it "should allow definition of remember strategy" do
    strategy(:remember) do
      'rspec'
    end

    settings.authlane[:remember_strategy].yield.should == 'rspec'
  end

  it "should allow definition of forget strategy" do
    strategy(:forget) do
      'rspec'
    end

    settings.authlane[:forget_strategy].yield.should == 'rspec'
  end
end
