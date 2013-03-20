require 'spec_helper'
require_relative "../lib/rack/flasher.rb"
class Rack::Flasher # to cut down on writing

  shared_examples_for "Any instance of HashOfArrays" do
    its(:default_proc) { should == HashOfArrays::DEFAULT_BLOCK }
    its("values.first") { should respond_to :push }
  end
  
  shared_examples_for "Any Flasher hash" do
      it { should_not be_nil }
      it { should respond_to :sweep! }
      it { should respond_to :keep }
      it { should respond_to :discard }
      it { should respond_to :"[]" }
      it { should respond_to :"[]=" }
      it { should respond_to :keys }
      it { should respond_to :values }
      it { should respond_to :each }
  end

  shared_context "session to flash" do  
    let(:session) {
      { :info => "Welcome back!", :errors =>  ["You need to update your password.",""]}
    }
    let(:flash) { FlashHash[session] }
  end

  shared_context "stuff added to flash" do
    before do
      flash[:one] << "My thumb"
      flash[:two] << "My shoe"
      flash[:three] << "My knee"
      flash[:info] << "More info!"
    end
  end
  
  describe "Rack::Flasher::FlashHash" do
  
    context "Given a nil argument" do
      subject { FlashHash.new(nil) }
      it_should_behave_like "Any Flasher hash"
    end
  
    context "Given a hash" do
      subject { flash }
      context "that is empty" do
        let(:flash) { FlashHash[{}] }
        it_should_behave_like "Any Flasher hash"
      end
  
      context "with session values in" do
        shared_examples "now and next" do
          its(:now) { should == {:info=>["Welcome back!"], :errors=>["You need to update your password.", ""] } }
          its(:next) { should == {:info=>["More info!"],:one=>["My thumb"], :two=>["My shoe"], :three=>["My knee"]} }
        end
  
        shared_examples "The contents of now" do
          its([:info]) { should == ["Welcome back!"] }
          its([:info]) { should be_a_kind_of Array }
          its([:errors]) { should be_a_kind_of Array }
          its([:errors]) { should include "You need to update your password." }
          its([:errors]) { should include "" }
        end
        include_context "session to flash"
        include_context "stuff added to flash"

        it_should_behave_like "Any Flasher hash"
        it_should_behave_like "now and next"
        it_should_behave_like "The contents of now" do
          subject { flash.now }
        end
  
        describe "Sweeping" do
          context "Not swept yet" do
            its("now.length"){ should == 2 }
            its("next.length"){ should == 4 }
          end
          context "One sweep" do
            before do
              flash.sweep!
            end
            its("now.length"){ should == 4 }
            its("next.length"){ should == 0 }
            context "Two sweeps" do
              before do
                flash.sweep!
              end
              it { should be_empty }
              its(:length){ should == 0 }          
            end
          end
        end
  
        describe "Discarding" do
          context "Nothin done yet" do
            its("now.length"){ should == 2 }
            its("next.length"){ should == 4 }
          end
          context "The whole flash" do
            before do
              flash.discard
              flash.sweep!
            end
            it { should be_empty }
          end
          context "A particular key" do
            before do
              flash.discard(:two)
              flash.sweep!
            end
            its("now.length") { should == 3 }
          end
        end
  
        describe "Keeping" do
          context "Nothin done yet" do
            its("now.length"){ should == 2 }
            its("next.length"){ should == 4 }
          end
          context "The whole flash" do
            context "With no values in next" do
              before do
                flash.sweep!
                flash.keep
                flash.sweep!
              end
              its("now.length"){ should == 4 }
              its("next.length"){ should == 0 }
            end
          end
          context "A particular key" do
            context "When there are values in the next" do
            # THIS REQUIRES A SPECIAL MERGE!
              before do
                flash.keep(:info)
                flash.sweep!
              end
              its("now.length"){ should == 4 }
              its("next.length"){ should == 0 }
            end
            context "When there are no values in the next" do
              before do
                flash.sweep!
                flash.keep(:three)
                flash.sweep!
              end
              its("now.length"){ should == 1 }
            end
          end        
        end
  
        describe "Setting" do
          context "Given a value" do
            context "but without specifying now or next" do
              context "for a value with a new key" do
                before do
                  flash[:foo] << "bar"
                end
                its([:foo]) { should == ["bar"] }
                its(:now) { subject.now[:foo].should == [] }
                its(:next) { subject[:foo].should == ["bar"] }
                context "but after a sweep too" do
                  before do
                    flash.sweep!
                  end
                  its([:foo]) { should == [] }
                  its(:now) { subject.now[:foo].should == ["bar"] }
                  its(:next) { subject[:foo].should == [] }
                end
              end
              context "for a value with an existing key" do
                before do
                  flash[:info] << "Extra info!"
                end
                its([:info]) { should == ["More info!", "Extra info!"] }
                its(:now) { subject.now[:info].should == ["Welcome back!"] }
                its(:next) { subject[:info].should == ["More info!", "Extra info!"] }
                context "but after a sweep too" do
                  before do
                    flash.sweep!
                  end
                  its([:info]) { should == [] }
                  its(:now) { subject.now[:info].should == ["More info!", "Extra info!"] }
                  its(:next) { subject[:info].should == [] }
                end
              end
            end
            context "via `now`" do
              context "for a value with a new key" do
                before do
                  flash.now[:bar] << "foo"
                end
                its([:bar]) { should == [] }
                its(:now) { subject.now[:bar].should == ["foo"] }
                its(:next) { subject[:bar].should == [] }
                context "but after sweeping" do
                  before do
                    flash.sweep!
                  end
                  subject { flash.now[:bar] }
                  it { should respond_to :push }
                  it { should be_empty }            
                end
              end
              context "for a value with an existing key" do
                before do
                  flash.now[:info] << "Extra info!"
                end
                its([:info]) { should == ["More info!"] }
                its(:now) { subject.now[:info].should == ["Welcome back!", "Extra info!"] }
                its(:next) { subject[:info].should == ["More info!"] }
                context "but after sweeping" do
                  before do
                    flash.sweep!
                  end
                  subject { flash.now[:info] }
                  it { should respond_to :push }
                  it { should == ["More info!"] }            
                end
              end
            end
          end
        end
  
      end
    
    end
    
  end
end