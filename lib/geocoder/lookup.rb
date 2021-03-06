require 'net/http'

module Geocoder
  module Lookup
    extend self

    ##
    # Query Google for the coordinates of the given address.
    #
    def coordinates(address, geocoder)
      @geocoder = geocoder
      if (results = search(address)).size > 0
        if @geocoder == :waze
          place = results.first['location']
          ['lat', 'lon'].map{ |i| place[i] }
        else
          # Google Geocoder
          place = results.first.geometry['location']
          ['lat', 'lng'].map{ |i| place[i] }
        end
      end
    end

    ##
    # Query Google for the address of the given coordinates.
    #
    def address(latitude, longitude)
      if (results = search(latitude, longitude)).size > 0
        results.first.formatted_address
      end
    end

    ##
    # Takes a search string (eg: "Mississippi Coast Coliseumf, Biloxi, MS") for
    # geocoding, or coordinates (latitude, longitude) for reverse geocoding.
    # Returns an array of Geocoder::Result objects,
    # or nil if not found or if network error.
    #
    def search(*args)
      return [] if args[0].blank?
      doc = parsed_response(args.join(","), args.size == 2)
      if @geocoder == :waze
        return doc
      else
        res = [].tap do |results|
          if doc
            doc['results'].each{ |r| results << Result.new(r) }
          end
        end
        return res
      end
    end


    private # ---------------------------------------------------------------

    ##
    # Returns a parsed Google geocoder search result (hash).
    # Returns nil if non-200 HTTP response, timeout, or other error.
    #
    def parsed_response(query, reverse = false)
      begin
        doc = ActiveSupport::JSON.decode(fetch_data(query, reverse))
      rescue SocketError
        warn "Geocoding API connection cannot be established."
      rescue TimeoutError
        warn "Geocoding API not responding fast enough " +
          "(see Geocoder::Configuration.timeout to set limit)."
      end

      if @geocoder == :google
        case doc['status']; 
        when "OVER_QUERY_LIMIT"
          warn "Geocoding API error: over query limit."
          doc = nil
        when "REQUEST_DENIED"
          warn "Geocoding API error: request denied."
          doc = nil
        when "INVALID_REQUEST"
          warn "Geocoding API error: invalid request."
          doc = nil
        end
      end
      
      doc 
    end

    ##
    # Fetches a raw Google geocoder search result (JSON string).
    #
    def fetch_data(query, reverse = false)
      return nil if query.blank?
      url = query_url(query, reverse)
      timeout(Geocoder::Configuration.timeout) do
        Net::HTTP.get_response(URI.parse(url)).body
      end
    end

    def query_url(query, reverse = false)
      params = {
        (reverse ? :latlng : :address) => query,
        :sensor => "false"
      }
      
      case @geocoder;
      when :google
        "http://maps.google.com/maps/api/geocode/json?" + params.to_query
      when :waze
        "http://www.waze.co.il/WAS/mozi?q=#{CGI::escape query}&token=#{Geocoder::Configuration.waze_api_key}"
      end
    end
  end
end

