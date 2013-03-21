config_path = File.expand_path '../../../examples/simplest/config.rb', File.dirname(__FILE__)
require_relative config_path

require 'sinatra/base'

shared_context "All routes" do |options={}|
  include Rack::Test::Methods
  let(:app){ Example.app options }
end

shared_examples_for "Any route" do
  subject { last_response }
  it { should be_ok }
end
# shared_context "All routes" do |options={}|
#   include Capybara::DSL 
#   Capybara.app = Example.app options
# end