class AddAttributesToVariants < ActiveRecord::Migration
  def self.up
    add_column :variants, :style_clr_code, :string
    add_column :variants, :barcode, :string
  end

  def self.down
    remove_column :variants, :style_clr_code
    remove_column :variants, :barcode
  end
end