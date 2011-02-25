module Geocoder
  class Configuration
    cattr_accessor :timeout
  end
end

Geocoder::Configuration.timeout = 3
Geocoder::Configuration.waze_api_key = "7d670924-136a-4b12-95e4-de90ed149c60"


