require 'rack'

module Rack
  class FlashRequest < Request
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
    def flash
      @env[@rack_flash]
    end
    def flash=( replacement )
      @env[@rack_flash] = Flasher::FlashHashes( replacement )
    end
    def flash?
      flash && !flash.empty?
    end
    def flash_to_session!
      flash.rotate!
      fhs = {}
      flash.each do |k,v|
        fhs[k] = Hash[v.next]
      end
        
      session[@rack_flash] = fhs
    end
  end

  class Flasher

    # A hash that holds several of FlashHash.
    # It's here so that you can have application specific
    # flash hashes e.g. {:app => flash_hash1, :api => flash_hash2}…
    class FlashHashes < ::Hash

      # This callback rotates any flash structure we referenced, placing the 'next' hash into the session
      # for the next request.
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

      # @see ::Hash
      def initialize(*args,&block)
        super
        self.default_proc = DEFAULT_BLOCK unless block
      end

      def self.[]( other_hash )
        return other_hash if other_hash.kind_of? self
        instance = self.new
        other_hash.each do |k,v|
          instance[k] = v.respond_to?(:push) ? v : [v]
        end
        instance
      end

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

      def merge_and_mix!( other_hash )
        self.replace self.merge_and_mix other_hash
      end
          
    end

    # A subclass of Hash that "remembers forward" by exactly one action.
    # Design decisions:
    # * It's more important to make storage easy than to retrieval, as retrieval will rarely be ad hoc.
    # * A value can be multiple.
    class FlashHash
      require 'forwardable'
      extend Forwardable

      # Builds a new FlashHash.
      def initialize( *args, &block )
        @now = HashOfArrays.new *args, &block
        @now.default = [] unless args || block
        @next = @now.dup
      end

      attr_reader :now, :next

      def self.[]( other_hash )
        duped = other_hash.dup
        duped = HashOfArrays[duped] unless duped.kind_of? HashOfArrays
        instance = FlashHash.new
        instance.instance_variable_set :@now, duped
        instance
      end


      def []( key )
        @next[key]
      end
      

      # Swaps out the current flash for the future flash, then returns it.
      def sweep!
        @now = @next.dup
        @next.clear
        @now
      end
      
      # Keep all or one of the current values for next time.
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
    def self.FlashHashes( hash={} )
      h = FlashHashes.new
      hash.each do |k,v|
        h[k] = FlashHash[v]
      end
      h
    end

#--------------------

    def initialize( app, options={} )
      @app, @options  = app, options
    end


    def call( env )
      request = Rack::FlashRequest.new(env, @options)

      status, headers, body = @app.call(env)

      request.flash_to_session!

      [status, headers, body]
    end
  end
end