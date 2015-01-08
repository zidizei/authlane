require 'authlane/version'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :doc do
  desc 'Generate YARD documentation database'
  task :generate do
    system 'rm -rf .yardoc'
    system 'yardoc'
  end

  desc 'Start the YARD documentation server'
  task :srv do
    system 'yard server --reload -- Kargo'
  end

  desc 'Open generated YARD documentation website'
  task :open do
    system 'open doc/index.html'
  end
end

RSpec::Core::RakeTask.new(:spec)

Dir['tasks/*.rake'].sort.each { |ext| load ext }
