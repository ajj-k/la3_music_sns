require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'dotenv/load'

enable :sessions

before do
   Dotenv.load
   Cloudinary.config do |config|
   config.cloud_name = ENV['CLOUD_NAME']
   config.api_key    = ENV['CLOUDINARY_API_KEY']
   config.api_secret = ENV['CLOUDINARY_API_SECRET']
   end
end

get '/' do
    erb :index
end

get '/signup' do
    erb :sign_up
end

post '/signup' do
    @user = User.create(name: params[:name], password: params[:password],
                        password_confirmation: params[:password_confirmation],
                        image: params[:icon])
    if @user.persisted?
        session[:user] = @user.id
    end
    redirect '/'
end

post '/login' do
    user = User.find_by(name: params[:name])
   if user && user.authenticate(params[:password])
      session[:user] = user.id 
   end
   redirect '/'
end

post '/logout' do
   session[:user] = nil
   redirect '/'
end