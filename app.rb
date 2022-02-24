require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'open-uri'
require 'json'
require 'net/http'
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

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

get '/' do
    erb :index
end

get '/signup' do
    erb :sign_up
end

get '/home' do
   erb :home 
end

get '/search' do
    uri = URI("https://itunes.apple.com/search?")
    uri.query = URI.encode_www_form({
        term: params["search"],
        media: "music",
        country: "JP",
        limit: 30
    })
    res = Net::HTTP.get_response(uri)
    json = JSON.parse(res.body)
    @song_results = json["results"]
    erb :search
end

post '/signup' do
    img_url = ''
    if params[:file]
       img = params[:file]
       tempfile = img[:tempfile]
       upload = Cloudinary::Uploader.upload(tempfile.path)
       img_url = upload['url']
    end
    
    @user = User.create(name: params[:user], password: params[:password],
                        password_confirmation: params[:password_confirmation],
                        image: img_url)
    if @user.persisted?
        session[:user] = @user.id
    end
    redirect '/'
end

post '/login' do
    user = User.find_by(name: params[:user])
   if user && user.authenticate(params[:password])
      session[:user] = user.id 
   end
   redirect '/'
end

get '/logout' do
   session[:user] = nil
   erb :index
end

post '/post' do
    current_user.posts.create(
        image: params[:icon],
        artist: params[:artist],
        album: params[:album],
        song: params[:song],
        sample: params[:sample],
        comment: params[:comment]
        )
    redirect '/home'
end

get '/post/:id/edit' do
    @post = Post.find(params[:id])
    erb :edit
end

post '/post/:id/edit' do
   post = Post.find(params[:id])
   post.comment = params[:comment] 
   post.save
   redirect '/home'
end

get '/post/:id/del' do
   post = Post.find(params[:id])
   post.destroy
   erb :home
end

get '/post/:id/like' do
    post = Post.find(params[:id])
    #like = Post.find(params[:id])
    current_user.likes.create(
        user_id: session[:user],
        post_id: params[:id]
        )
    puts "liked"
    redirect "/home"
end

get '/post/:id/del_like' do
   post = current_user.likes.find_by(post_id: params[:id])
   puts post.id
   post.destroy
   post.save
   puts "delete"
   redirect "/home"
end