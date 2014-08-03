require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'oauth'
require 'twitter'
retuire 'omniauth-venmo'

require './server'

use Rack::Session::Cookie

run Sinatra::Application