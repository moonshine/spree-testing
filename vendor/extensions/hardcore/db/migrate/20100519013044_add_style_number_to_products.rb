class AddStyleNumberToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :style_number, :string
  end

  def self.down
    remove_column :products, :style_number
  end
end