require 'geocoder'

module Geocoder
  if defined? Rails::Railtie
    require 'rails'
    class Railtie < Rails::Railtie

      initializer 'geocoder.insert_into_active_record' do
        ActiveSupport.on_load :active_record do
          Geocoder::Railtie.insert_into_active_record
        end
      end

      initializer 'geocoder.insert_into_mongoid' do
        ActiveSupport.on_load :mongoid do
          Geocoder::Railtie.insert_into_mongoid
        end
      end

      rake_tasks do
        load "tasks/geocoder.rake"
      end
    end
  end

  class Railtie

    def self.insert_into_active_record
      if defined?(::ActiveRecord::Base)
        Geocoder::Railtie.insert(::ActiveRecord::Base)
      end
    end

    def self.insert_into_mongoid
      if defined?(::Mongoid::Document)
        Geocoder::Railtie.insert(::Mongoid::Document)
      end
    end

    def self.insert(target)

      return unless defined?(target)

      ##
      # Add methods to target so Geocoder is accessible by models.
      #
      target.class_eval do

        ##
        # Set attribute names and include the Geocoder module.
        #
        def self.geocoded_by(address_attr, options = {})
          _geocoder_init(
            :user_address => address_attr,
            :latitude  => options[:latitude]  || :latitude,
            :longitude => options[:longitude] || :longitude
          )
        end

        ##
        # Set attribute names and include the Geocoder module.
        #
        def self.reverse_geocoded_by(latitude_attr, longitude_attr, options = {})
          _geocoder_init(
            :fetched_address => options[:address] || :address,
            :latitude  => latitude_attr,
            :longitude => longitude_attr
          )
        end

        def self._geocoder_init(options)
          unless _geocoder_initialized?
            class_inheritable_reader :geocoder_options
            class_inheritable_hash_writer :geocoder_options
          end
          self.geocoder_options = options
          unless _geocoder_initialized?
            include _geocoder_driver
          end
        end

        def self._geocoder_initialized?
          included_modules.include? _geocoder_driver
        end

        def self._geocoder_driver
          if defined?(::ActiveRecord::Base) and ancestors.include?(::ActiveRecord::Base)
            Geocoder::ActiveRecord
          elsif defined?(::Mongoid::Document) and included_modules.include?(::Mongoid::Document)
            Geocoder::Mongoid
          end
        end
      end

    end
  end
end
