# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class HardcoreExtension < Spree::Extension
  version "1.0"
  description "Hardcore Shop"
  url "http://www.hardcore.com.au"

  def self.require_gems(config)
    config.gem 'fastercsv', :version => '>=1.5.3'
  end

  def activate

    # Don't show zero stock product
    #Spree::Config.set(:show_zero_stock_products => false)
    #Spree::Config.set(:logo => '/images/admin/bg/globe-logo.gif')

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end

    Variant.class_eval do
      self.additional_fields += [{:name => 'style_number', :only => [:product]},
                                 {:name => 'style_clr_code', :only => [:variant]},
                                 {:name => 'barcode', :only => [:variant]}]
      #validates_presence_of :style_clr_code, :barcode
      #validates_uniqueness_of :style_clr_code, :barcode
    end


    Product.class_eval do
      validates_presence_of :style_number
      validates_uniqueness_of :style_number

    end

  end
end
