require 'sinatra/base'
require 'haml'
dir = File.dirname __FILE__
require File.expand_path "../../lib/rack/flasher.rb", dir
require File.expand_path "../../lib/sinatra/flasher.rb", dir

module Example
  class App < Sinatra::Base
    helpers Sinatra::Flasher

    enable :inline_templates

    get "/" do
      flash[:info] << "You just left the index page."
      haml :index
    end

    get "/login" do
      session[:user] = 1
      flash.now[:info] << "Try logging in."
      haml :"login-fail"
    end

    post "/login" do
      if params[:user].to_i == 1
        session[:user] = params[:user]
        flash[:info] << "Welcome back!"
        redirect "/"
      else
        flash.now[:warning] << "Login failed. Try again."        
        haml :"login-succeed"
      end
    end
    
    get "/logout" do
      flash.now[:info] << "Goodbye!"
      s = <<STR
<p>Flash</p>
<p><a href="/login">Login</a></p>
STR
    end

    get "/flash" do
      # all flash messages end up here.
      flash[:info].now +
      flash[:info].next
    end
    run! if __FILE__ == $0
  end

  def self.app( options={} )
    Rack::Builder.app do      
      use Rack::Session::Cookie,  :path => '/',
                                  :secret => 'change_me'
      use Rack::Flasher
      run Example::App
    end
  end
end


__END__
@@layout
- warn "Entering layout"
!!!
%head
  %title Example
%body
  = styled_flash
  = yield

@@index
<a href="/login">Login</a>

@@login-fail
%form{ method: "POST" }
  %input{ type: "submit", value: "login!" }

@@login-succeed
%form{ method: "POST" }
  %input{ type: "hidden", value: "1", name: "user", id: "user" }
  %input{ type: "submit", value: "login!" }