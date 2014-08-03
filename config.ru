require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'oauth'
require 'twitter'
retuire 'omniauth-venmo'

require './server'
run Sinatra::Application