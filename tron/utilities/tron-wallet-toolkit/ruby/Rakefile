# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop is not available
  desc 'Run RuboCop (not available)'
  task :rubocop do
    puts 'RuboCop is not available. Add it to your Gemfile to run this task.'
  end
end

task :default => :test

desc "Build the gem"
task :build do
  system("gem", "build", "tron.gemspec")
end

desc "Install the gem"
task :install => :build do
  system("gem", "install", "tron.rb-#{File.read('lib/tron/version.rb').match(/VERSION = ['"](.+)['"]/)[1]}.gem")
end