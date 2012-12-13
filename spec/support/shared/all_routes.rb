require_relative "../../../lib/rack/flasher.rb"


module App

  def self.app( options={} )
    Rack::Builder.app do
      use Rack::Flasher, options
      routes = lambda { |e|
        request = Rack::Request.new(e)
        Rack::Response.new( [""], 200, {"Content-Type" => "text/html"}
        ).finish
      }
      run routes
    end
  end    
end

shared_context "All routes" do |options={}|
  include Rack::Test::Methods
  warn "options = #{options.inspect}"
  let(:app){ App.app( options ) }
end

shared_examples_for "Any route" do
  subject { last_response }
  it { should be_ok }
end