# frozen_string_literal: true

class AddNameAndCodeToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column(:users, :name, :string) unless column_exists?(:users, :name)
    add_column(:users, :code, :string) unless column_exists?(:users, :code)
  end

  def down
    remove_column(:users, :name) if column_exists?(:users, :name)
    remove_column(:users, :code) if column_exists?(:users, :code)
  end
end
