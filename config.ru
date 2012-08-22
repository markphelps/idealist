require 'rubygems'
require 'bundler'

Bundler.require(:default, ENV['RACK_ENV'])

require './idealist'
run Sinatra::Application