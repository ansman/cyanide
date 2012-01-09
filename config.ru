root_dir = File.dirname(__FILE__)

require 'rubygems'
require 'sinatra'

require "#{root_dir}/cyanide.rb"
  
set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'cyanide.rb')
disable :run
 
run Sinatra::Application
