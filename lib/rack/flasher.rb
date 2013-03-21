require 'rack'

module Rack

  # A custom request class, to help deal with the flash easily.
  class FlashRequest < Request

    # @param [Hash] options
    # @option options [String] :rack_flash The key for the flash in the env. Defaults to 'rack.flash'.
    # @option options [Symbol] :flash_key The default key for the first flash hash. Defaults to :flash.
    def initialize(env, options={})
      @rack_flash = options.fetch :rack_flash, 'rack.flash'
      @flash_key = options.fetch :flash_key, :flash
      super(env)
      self.flash = if self.flash && !self.flash.empty?
        self.flash # flash= does a conversion, so not as pointless as it looks.
      elsif session && session[@rack_flash]
        session[ @rack_flash ]
      else
        { @flash_key => {} }
      end
    end


    # Retrieve the flash(es)
    # @return [Flasher::FlashHashes]
    def flash
      @env[@rack_flash]
    end


    # Replace the flash(es).
    # @param [Hash] replacement
    # @return [Flasher::FlashHashes]
    def flash=( replacement )
      @env[@rack_flash] = Flasher::FlashHashes( replacement )
    end


    # Is there a flash, and if so, does it have anything it it?
    # @return [true,false]
    def flash?
      flash && !flash.empty?
    end


    # Moves the next flash to now, and then puts "now" into the session so that it's available on the next request.
    # @return [Hash]
    def flash_to_session!
      flash.rotate!
      session[@rack_flash] = flash.each_with_object({}) do |(k,v),fs|
        fs[k] = Hash[v.now]
      end
    end
  end


  # This class is the Rack middleware and a namespace.
  # It's namespacing the flash hash code.
  class Flasher

    # A hash that holds several of {FlashHash}.
    # It's here so that you can have application specific
    # flash hashes
    # @example If you wanted several flashes, it would resemble this.
    #   {:app => flash_hash1,
    #    :api => flash_hash2
    #    #…
    #   }
    #   # but the default is this:
    #   {:flash => flash_hash}
    class FlashHashes < ::Hash

      # This callback rotates any flash structure we referenced, placing the 'next' hash into the session
      # for the next request.
      # @return [self]
      def rotate!
        each do |k,v|
          v.sweep!
        end
        self
      end
    end


    # A hash that, by default, has each value as an array.
    # It does this by passing a block to `default_proc=`.
    # The `initialize` method signature respects the one
    # handed down by `::Hash`, so if you want to pass in
    # a different default proc, you may. I don't know why
    # you would, but you're an adult.
    class HashOfArrays < ::Hash
      # creates an array on first access of a key.
      DEFAULT_BLOCK = ->(h,k){ h[k] = [] }

      # @see ::Hash#new
      def initialize(*args,&block)
        super
        self.default_proc = DEFAULT_BLOCK unless block
      end


      # Converts a Hash to a HashOfArrays. If the given hash does
      # not keep its values in arrays then they are boxed in them.
      # @param [Hash] other_hash
      # @return [HashOfArrays]
      # @example
      #   h = { :info => "Welcome back!", :errors =>  ["You need to update your password.",""]}
      #   HashOfArrays[h]
      # => {:info=>["Welcome back!"], :errors=>["You need to update your password.", ""] }
      def self.[]( other_hash )
        return other_hash if other_hash.kind_of? self
        instance = self.new
        other_hash.each do |k,v|
          instance[k] = v.respond_to?(:push) ? v : [v]
        end
        instance
      end


      # Not just a merge, because a merge would overwrite existing
      # entries. This checks to see if there are existing entries,
      # and if so, pushes them on to the end of the array, thus
      # "mixing" them.
      # @param [Hash] other_hash
      # @return [HashOfArrays]
      def merge_and_mix( other_hash )
        duped = self.class.new()
        self.each do |k,v|
          duped[k] = Array.new(v)
        end

        self.class[other_hash].each do |k,v|
          if duped.has_key? k
            duped[k].concat v
          else
            duped[k] = v
          end
        end
        duped
      end


      # Replaces self with the new hash.
      # @see #merge_and_mix
      def merge_and_mix!( other_hash )
        self.replace self.merge_and_mix other_hash
      end
          
    end


    # A subclass of Hash that "remembers forward" by exactly one action.
    # Design decisions:
    # * It's more important to make storage easy than to retrieval, as retrieval will rarely be ad hoc.
    # * A value can be multiple, hence each value is an array.
    # All the usual hash methods are delegated to the *next* hash.
    class FlashHash
      require 'forwardable'
      extend Forwardable

      # Builds a new FlashHash.
      # @see ::Hash#new
      def initialize( *args, &block )
        @now = HashOfArrays.new *args, &block
        @now.default = [] unless args || block
        @next = @now.dup
      end


      # @!attribute [r] now
      # @return [HashOfArrays] the hash for *this* request.
      attr_reader :now

      # @!attribute [r] next
      # @return [HashOfArrays] the hash for the next request.
      attr_reader :next


      # Converts a hash to a FlashHash.
      # @param [Hash] other_hash
      # @return [FlashHash]
      def self.[]( other_hash )
        duped = other_hash.dup
        duped = HashOfArrays[duped] unless duped.kind_of? HashOfArrays
        instance = FlashHash.new
        instance.instance_variable_set :@now, duped
        instance
      end


      # Retrieves a value from the *next* hash.
      # @param [Symbol] key
      def []( key )
        @next[key]
      end
      

      # Swaps out the current flash for the future flash, then returns it.
      # @return [HashOfArrays]
      def sweep!
        @now = @next.dup
        @next.clear
        @now
      end


      # Keep all or one of the current values for next time.
      # @param [Symbol] key
      # @return (see HashOfArrays#merge_and_mix!)
      def keep(key=nil)
        if key
          if @next[key].nil? || @next[key].empty?
            @next[key] = @now[key]
          else
            @next[key].concat @now[key]
          end
        else
          @next.merge_and_mix!(@now)
        end
      end


      # Tosses any values or one value before next time.
      # @param [Symbol] key
      # @return [HashOfArrays]
      def discard(key=nil)
        if key
          @next.delete(key)
        else
          block = default_proc || DEFAULT_BLOCK
          @next = HashOfArrays.new &block 
        end
      end

      def_delegators :"@next", *(::Hash.instance_methods(false) + Enumerable.instance_methods(false) - self.instance_methods(false))
    end


    # Converts a hash of hashes to a hash of FlashHashes.
    # If you want to convert a hash to a FlashHash use FlashHash#new
    # @param [Hash] hash
    # @return [FlashHashes]
    def self.FlashHashes( hash={} )
      h = FlashHashes.new
      hash.each do |k,v|
        h[k] = FlashHash[v]
      end
      h
    end

#--------------------

    # @param [#call] app
    # @param [Hash] options (see Rack::FlashRequest)
    # @example
    #  use Rack::Session::Cookie,  :path => '/',
    #                              :secret => 'change_me'
    #  use Rack::Flasher
    #  run Example::App
    def initialize( app, options={} )
      @app, @options  = app, options
    end


    # @param [Array] env
    def call( env )
      dup._call env
    end


    # For thread safety.
    # @param (see #call)
    def _call( env )
      request = Rack::FlashRequest.new(env, @options)

      status, headers, body = @app.call(env)

      request.flash_to_session!

      [status, headers, body]
    end
  end
end