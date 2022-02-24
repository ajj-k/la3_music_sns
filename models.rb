require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :posts
    has_many :likes
    has_many :liked_posts, through: :likes, source: :post, dependent: :destroy
end

class Post < ActiveRecord::Base
   belongs_to :user
   has_many :likes
   has_many :liked_users, through: :likes, source: :user, dependent: :destroy
end

class Like < ActiveRecord::Base
   belongs_to :user
   belongs_to :post
end