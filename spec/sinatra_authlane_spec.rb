require File.expand_path '../spec_helper.rb', __FILE__

describe Sinatra::AuthLane do
  def create_auth_strategy(&block)
    mock_app do
      register Sinatra::AuthLane

      Sinatra::AuthLane.create_auth_strategy &block
    end
  end

  def create_role_strategy(name = :roles, &block)
    mock_app do
      register Sinatra::AuthLane

      Sinatra::AuthLane.create_role_strategy(name, &block)
    end
  end

  def create_remember_strategy(&block)
    mock_app do
      register Sinatra::AuthLane

      Sinatra::AuthLane.create_remember_strategy &block
    end
  end

  def create_forget_strategy(&block)
    mock_app do
      register Sinatra::AuthLane

      Sinatra::AuthLane.create_forget_strategy &block
    end
  end


  it "should allow definition of auth strategy" do
    create_auth_strategy do
      'rspec'
    end

    settings.authlane[:auth_strategy].yield.should == 'rspec'
  end

  it "should allow definition of role strategy" do
    create_role_strategy do
      'rspec'
    end

    settings.authlane[:role_strategy][:roles].yield.should == 'rspec'
  end

  it "should allow definition of named role strategies" do
    create_role_strategy(:rspec1) do
      'rspec1'
    end

    settings.authlane[:role_strategy][:rspec1].yield.should == 'rspec1'
  end

  it "should allow definition of remember strategy" do
    create_remember_strategy do
      'rspec'
    end

    settings.authlane[:remember_strategy].yield.should == 'rspec'
  end

  it "should allow definition of forget strategy" do
    create_forget_strategy do
      'rspec'
    end

    settings.authlane[:forget_strategy].yield.should == 'rspec'
  end
end
