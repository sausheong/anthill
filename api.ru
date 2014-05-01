#\ -s puma

require 'rubygems'
require 'bundler'
Bundler.require
$stdout.sync = true
require 'securerandom'
require './api'
puts "api.ru"
run Rack::URLMap.new "/" => Sinatra::Application