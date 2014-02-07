require 'sinatra'
require 'omniauth-asana'
require 'ostruct'
require './Asana_Config'

$ASANA_CLIENT_ID = Asana_Config::ASANA_CLIENT_ID
$ASANA_CLIENT_SECRET = Asana_Config::ASANA_CLIENT_SECRET

set :port, Asana_Config::PORT

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :asana, $ASANA_CLIENT_ID, $ASANA_CLIENT_SECRET 
end

get '/' do
  if session[:auth]
    redirect '/success'
  else
    <<-HTML
    <p>Sinatra demo app for Asana OAuth</p>
    <a href='/auth/asana'><img src="/asana-oauth-button.png"</a>
    HTML
  end
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  session[:auth] = auth.credentials
  session[:uid] = auth.uid
  session[:user] = auth.info
  redirect '/'
end

get '/success' do
    <<-HTML
    Welcome, #{session[:user][:name]}!
    Your token is #{session[:auth].token}, your id is #{session[:uid]}
    <a href='/logout'>Logout</a>
    HTML
end

###############################

get '/auth/failure' do
  raise StandardError, params
end

get '/logout' do
  session.destroy
  redirect '/'
end

puts $ASANA_CLIENT_ID
puts $ASANA_CLIENT_SECRET 