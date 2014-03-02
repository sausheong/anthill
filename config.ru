#\ -s puma

require 'rubygems'
require 'bundler'
Bundler.require
$stdout.sync = true
require 'securerandom'
require './server'
run Rack::URLMap.new "/" => Sinatra::Application