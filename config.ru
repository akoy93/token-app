$stdout.sync = true

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'oauth'
require 'twitter'
require 'omniauth-venmo'

require './env' if File.exists? 'env.rb'
require './server'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :venmo, ENV['VENMO_CONSUMER_KEY'], ENV['VENMO_CONSUMER_SECRET'], :scope => 'access_profile,make_payments'
end

run Sinatra::Application