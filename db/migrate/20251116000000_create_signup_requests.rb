# frozen_string_literal: true

class CreateSignupRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :signup_requests do |t|
      t.string :email, null: false
      t.string :code, null: false
      t.datetime :expires_at
      t.datetime :used_at

      t.timestamps
    end

    add_index :signup_requests, [ :email, :code ]
    add_index :signup_requests, :expires_at
  end
end
