class CreateFriends < ActiveRecord::Migration[6.1]
  def change
    create_table :friends do |t|
      t.references :user, foreign_key: true
      t.integer :follow_id
    end
  end
end
