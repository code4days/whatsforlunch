module Sinatra
    module Routing
      module Weathers
class Weathers

  attr_reader :lat, :lon, :description, :temperature

  def initialize(lat, lon)
    @lat = lat
    @lon = lon

    display_weather
  end

  def call_open_weather_api(url)
    json_response = HTTParty.get(url).body
    return JSON.parse( json_response )
  end

  def display_weather

    url = "http://api.openweathermap.org/data/2.5/weather?lat="+@lat.to_s+"&lon="+@lon.to_s+"&type=like&units=imperial"

    parsed_weather_result = call_open_weather_api(url)
    #pp parsed_weather_result
    parsed_weather_result['weather'].each do |result|
      if result['description'] != nil
        @description = result['description']
      end
    end

    #puts 'description:'+ @description
    if parsed_weather_result['main']['temp'] != nil
      @temperature = parsed_weather_result['main']['temp']
    end
    #puts 'temperature:'+ @temperature.to_s


    # @weatherStatus = "It is currently #{temp} and #{@description} outside."


  end
end
    end
    end
end
