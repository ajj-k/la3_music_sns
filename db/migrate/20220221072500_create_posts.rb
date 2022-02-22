class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
      t.references :user, foreign_key: true
      t.string :image
      t.string :artist
      t.string :album
      t.string :comment
      t.string :song
      t.string :sample
    end
  end
end
