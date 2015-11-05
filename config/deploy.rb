require 'bundler/setup'
require "rvm/capistrano"
require 'bundler/capistrano'
require 'whenever/capistrano'

set :stages, %W(avalon matterhorn uvastaging)
set :default_stage, "uvastaging"
require 'capistrano/ext/multistage'

set(:whenever_command) { "bundle exec whenever" }
set(:bundle_flags) { "--quiet --path=#{deploy_to}/shared/gems" }
set :rvm_ruby_string, "2.1.5"
#set :rvm_type, :system
set :rvm_path, "/home/dpg3k/.rvm/bin/rvm"

set :scm, :git
set :keep_releases, 3

task :uname do
  run "uname -a"
end
