require 'sinatra'
require 'omniauth-asana'
require 'ostruct'

set :port, ENV['PORT']
set :public_folder, "../public/"

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :asana, ENV['ASANA_CLIENT_ID'], ENV['ASANA_CLIENT_SECRET']
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

get '/success' do
    <<-HTML
    Welcome, #{session[:user][:name]}!
    Auth.refresh_token returns #{session[:auth].refresh_token}!
    Extra is #{session[:extra]}!
    Creds is #{session[:auth]}
    Your token is #{session[:auth][:refresh_token]}, your id is #{session[:uid]}
    <a href='/logout'>Logout</a>
    HTML
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  session[:auth] = auth.credentials
  session[:uid] = auth.uid
  session[:user] = auth.info
  session[:extra] = auth.extra
  redirect '/'
end

get '/auth/failure' do
  raise StandardError, params
end

get '/logout' do
  session.destroy
  redirect '/'
end
