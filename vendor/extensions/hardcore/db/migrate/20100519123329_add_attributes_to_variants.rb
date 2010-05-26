class AddAttributesToVariants < ActiveRecord::Migration
  def self.up
    add_column :variants, :style_clr_code, :string unless Variant.column_names.include?('style_clr_code')
    add_column :variants, :barcode, :string unless Variant.column_names.include?('barcode')
  end

  def self.down
    remove_column :variants, :style_clr_code
    remove_column :variants, :barcode
  end
end