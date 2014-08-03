require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'oauth'
require 'twitter'
require 'omniauth-venmo'

require './env'
require './server'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :venmo, ENV['VENMO_CONSUMER_KEY'], ENV['VENMO_CONSUMER_SECRET'], :scope => 'access_profile,make_payments'
end

run Sinatra::Application