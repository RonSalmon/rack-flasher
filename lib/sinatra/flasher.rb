
module Sinatra
  module Flasher
    def flash(key=:flash)
      k = key.to_sym
      env['rack.flash'][k] ||= Rack::Flasher::FlashHash.new
      env['rack.flash'][k]
    end

    # This block provides the default styling for the styled_flash method.
    DEFAULT_BLOCK = ->(klass,flashhash) do
      filling = flashhash.map{|klass,messages|
        messages.map{|message|
          "<div class='flash #{klass}'><p>#{message}</p></div>\n"
        }.join
      }.join
      %Q!<div id='#{klass}'>#{filling}</div>!
    end
  
    def styled_flash(key=:flash, &block)
      if key.respond_to? :call
        block = key
        key = :flash
      end
      key = key.to_sym # just in case
      now = flash(key).now
      return "" if now.empty?
      block = DEFAULT_BLOCK if block.nil?
      output = block.call key, now
    end
  end
end