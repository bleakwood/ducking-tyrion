class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :encrypted_password
      t.integer :sign_in_count, default: 0
      t.datetime :last_sign_in_at
      t.float :total_active_time, default: 0

      t.timestamps
    end
  end
end
