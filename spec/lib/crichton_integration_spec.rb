require 'spec_helper'
require 'rake'
require 'dice_bag/tasks'


describe Crichton do
  before do
    Crichton.reset
    Crichton.clear_config
    require File.expand_path("../../dummy/config/environment", __FILE__)
    require 'rspec/rails'
    
  end

  # This restores the global setting - one of the tests sets this value to a generated value and that causes other
  # tests to fail later on - depending on the order of the tests.
  after do
    Object.send(:remove_const, :Rails)
    Crichton.clear_config
    Crichton.config_directory = File.join('spec', 'fixtures', 'config')
    Crichton.reset
  end
  
  describe '.descriptor_registry', :type => :controller do 
    it 'initializes the registry if the registry is not already initialized' do
      get :index
    end
  end
  
end