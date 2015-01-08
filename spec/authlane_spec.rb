require 'authlane'

describe 'Authlane Version' do
  it 'is set to 0.1.0' do
    Authlane::VERSION.should eql('0.1.0')
  end
end
