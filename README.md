# Rack::Flasher #

Flash mashed for Rack using bits of Rack-Flash and Sinatra-Flash, and the melted butter of my mind.

## Why? ##

Because I want to use a _Rack_ flash, but the current [Rack Flash library](https://rubygems.org/gems/rack-flash3) is difficult to use and the source makes no sense to me. [Sinatra Flash](https://rubygems.org/gems/sinatra-flash) has a nice implementation for the flash hash, it's easy to follow, all it needs is conversion to Rack middleware.

## Also… ##

If you're reading this it's because you want to choose a flash library, and you're wondering "why this one?". Here's what I don't like about the others:

* Rack-Flash sometimes doesn't work for me.
* The "hash" it uses doesn't implement `each`, which makes it more difficult for others to use.
* Sinatra-Flash is great, as long as you only want to use it in a single application.
* All the flashes I've seen assign to the flash using something like `flash[:key] = "value"`, which doesn't make sense across apps - what happens when you want 2 different apps to add an `:error` to the flash?
* They always emphasise ease of access over ease of assignment. When you think about it, you're more likely to write the access once into a helper, but always have to write to the flash, so it would be better the other way round.


Some nice things about the others:

* Sinatra flash has a nice helper method.
* It also uses some nice language in the library that helps make sense when you read it, `now`, `next`, `styled_flash`, `keep` etc.
* The Rack one works across applications (as long as you don't clobber the current values).
* The Rack one also allows you to set up several hashes, so you can have one per app, for example.

## So, the philosophy leading to the implementation here is… ##

* It's Rack based, so it will work across apps.
* All apps can access any flash, but you can also have several flashes concurrently, so an app can have its own flash.
* Assignment is done via `flash[:key] << "value"`, so that existing values aren't clobbered and so you can re-use a key multiple times.
* The flash is written so that writing to it is easier to code against, reading is more fiddly because it will be a one-off job (if that, see next point!).
* It gives a Sinatra helper for rendering the flash.
* A lot of the straightforward language of the Sinatra-Flash library has been kept.
* The flash hash implements enumerable (in fact, it delegates to an underlying hash, but that will become clearer as you delve into the docs).


## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
