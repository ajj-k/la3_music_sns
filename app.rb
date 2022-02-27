require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'open-uri'
require 'json'
require 'net/http'
require 'dotenv/load'
require 'oauth'
require 'twitter'

consumer_key = '5HfH6eCoWnzFjoUJ28xlQdToC'
consumer_secret = 'afzFM7hW4tcELX4efV4lMs455pPkNxFRtKzCKuuwQ0CxikLrvX'
TWITTER_CALLBACK = 'http://localhost:9292/redirect'

consumer = OAuth::Consumer.new(
    consumer_key,
    consumer_secret,
    site: 'https://api.twitter.com/',
    #    :schema => :header,
    #    :method => :post,
    )


enable :sessions

before do
   Dotenv.load
   Cloudinary.config do |config|
   config.cloud_name = ENV['CLOUD_NAME']
   config.api_key    = ENV['CLOUDINARY_API_KEY']
   config.api_secret = ENV['CLOUDINARY_API_SECRET']
   end
   @twitter = OAuth::AccessToken.new(consumer,session[:access_token],session[:section_token])
end

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

get '/' do
    puts Post.count
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

get '/follow/:id' do
    current_user.friends.create(
        user_id: session[:user],
        follow_id: params[:id]
        )
    redirect '/home'
end

get '/follow/:id/del' do
    follow = current_user.friends.find_by(follow_id: params[:id])
    follow.destroy
    follow.save
    redirect '/home'
end

get '/twitter' do
    callback_url = "https://342c1446a83b4ebe8d2cbcdbc3ff8e9f.vfs.cloud9.ap-northeast-1.amazonaws.com/redirect"
    puts callback_url
    request_token = consumer.get_request_token(:oauth_callback => callback_url)
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    puts session[:request_token]
    puts session[:request_token_secret]
    puts request_token.authorize_url
    redirect request_token.authorize_url
    #response = endpoint.get('https://api.twitter.com/1.1/statuses/user_timeline.json?count=5')
    #puts response.body
    #erb :index
end

get '/redirect' do
    puts "a"
   oauth_client = consumer
   request_token = OAuth::RequestToken.new(oauth_client, session[:request_token], session[:request_token_secret])
   access_token = oauth_client.get_access_token(request_token, oauth_verifier => params[:oauth_verifier])
   twitter_client = Twitter::Rest::Client.new do |config|
       config.consumer_key = consumer_key
       config.consumer_secret = consumer_secret
       config.access_token = access_token.token
       config.access_token_secret = access_token.secret
   end
   puts "Logged in #{twtter_client.user.name}"
end