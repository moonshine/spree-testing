namespace :spree do
  namespace :extensions do
    namespace :hardcore do
      desc "Copies public assets of the Hardcore to the instance public/ directory."
      task :update => :environment do
        is_svn_git_or_dir = proc {|path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
        Dir[HardcoreExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
          path = file.sub(HardcoreExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  


      # TODO: Implement FTP connection
      #       Preferences setting for FTP 
      namespace :import do
        # rake spree:extensions:hardcore:import:product
        desc "Fetch Product table from CSV file on FTP and import all into DB"
        task :products => :environment do
          file = "#{RAILS_ROOT}/IMPORT/products_20100517120000.csv"
          header = %w(STYLE_NUMBER STYLE_DESC STYLE_FLAG SUPPLIER BRAND CATEGORY GROUP DEMOGRAPHIC)
          products = FasterCSV.read(file, {:header_converters => :symbol, :headers => header } )
          products.each do |row|

            # adhoc import, do not care checking if the product exists or not
            # if existed, simply overriden the attributes
            # we ignore 'SUPPLIER' field because the end consumer won't need to know about this info
            # TODO: figure out the function of 'STYLE_FLAG'
            p = Product.find_by_style_number row[:style_number]
            
            # Create new if not found
            p ||= Product.new
            
            update_or_create = p.new_record? ? 'create' : 'update'
            
            p.name = row[:style_desc]
            p.price = 0 if p.new_record? # Price is avaialable in this table, but we do need price set if new product
            p.style_number = row[:style_number]
            p.description = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." #TODO: determine how to get description info
            
            
            # SEO Works :)
            # merge all keywords of fields then stripping spaces and comma-tize the string
            combined_keywords  = row[:style_number] + ' '
            combined_keywords += row[:brand] + ' '
            combined_keywords += row[:style_desc] + ' '
            combined_keywords += row[:category] + ' '
            combined_keywords += row[:category] + ' '
            combined_keywords += row[:group] + ' '
            combined_keywords += row[:demographic] unless row[:demographic] == 'N/A'
            keywords = combined_keywords.downcase.gsub(/\W+/, ',')
            
            p.meta_keywords = keywords
            #p.meta_description = 'Something goes here'


            if p.save

              # Create category taxon
              category_taxonomy = Taxonomy.find_or_create_by_name 'Categories'
              main_category_taxon = Taxon.find_or_create_by_name_and_taxonomy_id('Categories', category_taxonomy.id)
              category_taxon    = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id(row[:category], main_category_taxon.id, category_taxonomy.id)

              # Create brand taxon
              brand_taxonomy    = Taxonomy.find_or_create_by_name 'Brands'
              main_brand_taxon = Taxon.find_or_create_by_name_and_taxonomy_id('Brands', brand_taxonomy.id)
              brand_taxon       = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id(row[:brand], main_brand_taxon.id, brand_taxonomy.id)

              # Create group taxon
              group_taxonomy    = Taxonomy.find_or_create_by_name 'Groups'
              main_group_taxon = Taxon.find_or_create_by_name_and_taxonomy_id('Groups', group_taxonomy.id)
              group_taxon       = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id(row[:group], main_group_taxon.id, group_taxonomy.id)
              main_group_brand_taxon = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id('Brand', group_taxon.id, group_taxonomy.id)
              group_brand_taxon = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id(row[:brand], main_group_brand_taxon.id, group_taxonomy.id)

              # Add/Replace product's taxons
              p.taxons = [category_taxon, brand_taxon, group_brand_taxon]
              
              # Add Product Properties
              
              # Delete all existing properties
              ProductProperty.find_all_by_product_id(p.id).each { |pp| pp.delete }
              
              category_prop = Property.find_or_create_by_name_and_presentation("category", "Category")
              ProductProperty.create :property => category_prop, :product => p, :value => row[:category]
              brand_prop = Property.find_or_create_by_name_and_presentation("brand", "Brand")
              ProductProperty.create :property => brand_prop, :product => p, :value => row[:brand]
              group_prop = Property.find_or_create_by_name_and_presentation("group", "Group")
              ProductProperty.create :property => group_prop, :product => p, :value => row[:group]
              supplier_prop = Property.find_or_create_by_name_and_presentation("supplier", "Supplier")
              ProductProperty.create :property => supplier_prop, :product => p, :value => row[:supplier]
              
              puts "Success: #{update_or_create} product with style number #{p.style_number}"
            else
              puts "Failure: #{update_or_create} product with style number #{p.style_number}"
            end  
          end
        end
        
        
        
        desc "Fetch Variant Option table from CSV file on FTP"
        task :variants => :environment do
          file = "#{RAILS_ROOT}/IMPORT/options_20100517120000.csv"
          header = %w(STYLE_NUMBER STYLE_CLR_CODE RIDER SEASON AVAILABLE_DATE OPTION_1_GROUP OPTION_1_DESC OPTION_1_SORT OPTION_1_FLAG OPTION_IMAGE_1 OPTION_IMAGE_2 OPTION_IMAGE_3 OPTION_IMAGE_4 OPTION_IMAGE_5 OPTION_IMAGE_6 OPTION_IMAGE_7 OPTION_IMAGE_8 OPTION_2_GROUP OPTION_2_DESC OPTION_2_SORT OPTION_2_FLAG BARCODE)
          variants = FasterCSV.read(file, {:header_converters => :symbol, :headers => header } )

          variants.each do |row|
            p = Product.find_by_style_number(row[:style_number])
            update_or_create = p.new_record? ? 'create' : 'update'

            if p
              puts "------------------"
              p.available_on = row[:available_date].to_datetime unless row[:available_date].nil?

              if p.save
                puts "Success: #{update_or_create} AVAILABLE_ON for product with style number #{p.style_number}"
              else
                puts "Failure: #{update_or_create} AVAILABLE_ON product with style number #{p.style_number}"
              end

              v = Variant.find_by_sku(row[:barcode])
              v ||= Variant.new

              v.product_id = p.id
              v.barcode = row[:barcode]
              v.sku = row[:barcode]
              v.style_clr_code = row[:style_clr_code]
              
              unless row[:option_1_group].nil?
                option1_type = OptionType.find_or_create_by_name_and_presentation(row[:option_1_group], row[:option_1_group])
                option1_value = OptionValue.find_or_create_by_name_and_presentation_and_option_type_id(row[:option_1_desc],row[:option_1_desc], option1_type.id)
                
                v.option_values << option1_value
              end
              
              unless row[:option_2_group].nil?
                option2_type = OptionType.find_or_create_by_name_and_presentation(row[:option_2_group], row[:option_2_group])
                option2_value = OptionValue.find_or_create_by_name_and_presentation_and_option_type_id(row[:option_2_desc],row[:option_2_desc], option2_type.id)
                v.option_values << option2_value
              end
              
              #if p.has_variants?
              #  v = Variant.find_by_sku(row[:barcode])
              #  v ||= Variant.new
              #  update_or_create = v.new_record? ? 'create' : 'update'

              # Variant require product_id as min. prequisite
              #  v.product_id = p.id
              #  v.barcode = row[:barcode]
              #  v.sku = row[:barcode]
              #  v.style_clr_code = row[:style_clr_code]
              #else
              #  v = p.master
              #  update_or_create = 'update'
              #  v.barcode = row[:barcode]
              #  v.sku = row[:barcode]
              #  v.style_clr_code = row[:style_clr_code]
              #end
              
 
              if v.save
                puts "Success: #{update_or_create} variant with EAN #{v.sku} for Product #{p.style_number}"
              else
                puts "Failure: #{update_or_create} variant with EAN #{v.sku} for Product #{p.style_number}"
              end
            else
              puts "Could not find product #{p.style_number}"
            end
          end
        end

        desc "Fetch Stocking table from CSV file on FTP"
        task :stocks => :environment do
          file = "#{RAILS_ROOT}/IMPORT/stocks_20100517120000.csv"
          header = %w(BARCODE STOCK_LEVEL)
          stocks = FasterCSV.read(file, {:header_converters => :symbol, :headers => header } )

          stocks.each do |row|
            v = Variant.find_by_sku(row[:barcode])

            if v
              v.on_hand = row[:stock_level]
              puts "Updating stock for EAN #{v.sku} - done"
            else
              puts "EAN #{row[:barcode]} is not found - skip"
            end
          end
        end

        desc "Fetch Pricing table from CSV file on FTP"
        task :prices => :environment do
          file = "#{RAILS_ROOT}/IMPORT/prices_20100517120000.csv"
          header = %w(STYLE_CLR_CODE PRICE_SCHEME CURRENCY PRICE MSRP DISCOUNT)
          prices = FasterCSV.read(file, {:header_converters => :symbol, :headers => header } )

          prices.each do |row|
            v = Variant.find_by_style_clr_code(row[:style_clr_code])
            #TODO: skip multi-pricing for Skateshop
            # what to do with PRICE?
            # process Discount

            if v
              v.price = row[:msrp]
              if v.save
                puts "Updating price for EAN #{v.sku} - done"
              else
                puts "Updating price for EAN #{v.sku} - failed"
              end
            else
              puts "STYLE_CLR_CODE #{row[:style_clr_code]} is not found - skip"
            end
          end
        end
      
        desc "Fetch all tables from FTP and import into DB"
        task :all => :environment do
          Rake::Task["spree:extensions:hardcore:import:products"].invoke
          Rake::Task["spree:extensions:hardcore:import:variants"].invoke
          Rake::Task["spree:extensions:hardcore:import:stocks"].invoke
          Rake::Task["spree:extensions:hardcore:import:prices"].invoke
        end
      end
    end
  end
end
