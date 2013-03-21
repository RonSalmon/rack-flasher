require "bundler/gem_tasks"


# run task for examples

namespace :examples do

  desc <<-DESC
    Run examples.
  DESC
  task :run do
    exec "bin/rackup examples/simplest/config.ru"
  end

end

desc "(Re-) generate documentation and place it in the docs/ dir. Open the index.html file in there to read it."
task :docs => [:"docs:environment", :"docs:yard"]
namespace :docs do

  task :environment do
    ENV["RACK_ENV"] = "documentation"
  end

  require 'yard'

  YARD::Rake::YardocTask.new :yard do |t|
    t.files   = ['lib/**/*.rb', 'app/*.rb', 'spec/**/*.rb']
    t.options = ['-odocs/'] # optional
  end

end