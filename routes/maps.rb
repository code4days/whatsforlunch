
module Sinatra
    module Routing
      module Maps
      
class Maps

  attr_reader :lat, :lon

  def initialize(query)
      @query = query

      #get_location
  end

  def call_google_places_api(url)
          json_response = HTTParty.get(url).body
          return JSON.parse( json_response )
  end

  def get_position
      @query.gsub!(' ','%20')
      puts @query

      url = "https://maps.googleapis.com/maps/api/geocode/json?address="+@query+""

      parsed_result = call_google_places_api(url)
      #pp parsed_result

      #pp parsed_result
      parsed_result['results'].each do |result|
  	      x = result['geometry']['location']
          @lat = x['lat']
          @lon = x['lng']
          # puts @lat
          # puts @lon
      end
   end
end

    end
    end
end