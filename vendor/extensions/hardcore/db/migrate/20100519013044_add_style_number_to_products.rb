class AddStyleNumberToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :style_number, :string unless Product.column_names.include?('style_number')
  end

  def self.down
    remove_column :products, :style_number
  end
end