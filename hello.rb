require 'sinatra'
require 'omniauth-twitter'

use OmniAuth::Builder do
  provider :twitter, 'QFBr5gauJoOaVZ2Cy2qC8vOhx', ' VGKDbpvk09XQmcMHCIm1PwvtEZdMNQo8cndVnllAGQkDaThfZ2'
end

configure do
  enable :sessions
end
 
helpers do
  def admin?
    session[:admin]
  end
end
 
get '/' do
 'Hello World!'
end

get '/public' do
  "This is the public page - everybody is welcome!"
end
 
get '/private' do
  halt(401,'Not Authorized') unless admin?
  "This is the private page - members only"
end
 
get '/login' do
  redirect to("/auth/twitter")
end

get '/auth/twitter/callback' do
  env['omniauth.auth'] ? session[:admin] = true : halt(401,'Not Authorized')
  "You are now logged in"
end

get '/auth/failure' do
  params[:message]
end

get '/logout' do
  session[:admin] = nil
  "You are now logged out"
end