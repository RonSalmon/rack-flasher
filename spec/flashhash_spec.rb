require 'spec_helper'
require_relative "../lib/rack/flashhash.rb" 

shared_examples_for "Any Flasher hash" do
    it { should_not be_nil }
    it { should respond_to :sweep }
    it { should respond_to :keep }
    it { should respond_to :discard }
    it { should respond_to :"[]=" }
    it { should respond_to :keys }
    it { should respond_to :values }
end

describe "Rack::Flasher::Hash" do

  context "Given no argument" do
    subject { Rack::Flasher::Hash.new(nil) }
    it_should_behave_like "Any Flasher hash"
  end

  context "Given a hash" do

    context "that is empty" do
      subject { Rack::Flasher::Hash.new({}) }
      it_should_behave_like "Any Flasher hash"
    end

    context "with session values in" do
      let(:session) {
        { :info => "Welcome back!",
          :errors =>  ["You need to update your password.",
                       ""
                      ]
        }
      }
      subject { Rack::Flasher::Hash.new(session) }
      it_should_behave_like "Any Flasher hash"
      its(:now) { should == session }
      its(:next) { should == {} }
      describe "The contents of now" do
        subject { Rack::Flasher::Hash.new(session).now }
        its([:info]) { should == "Welcome back!" }
        its([:errors]) { should be_a_kind_of Array }
        its([:errors]) { subject.first.should == "You need to update your password." }
        its([:errors]) { subject.last.should == "" }
      end
    end
  
  end
  
end