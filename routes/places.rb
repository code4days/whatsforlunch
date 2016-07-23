
module Sinatra
    module Routing
      module Places
class Places

  attr_reader :lat, :lon, :address, :phone_number, :name, :rating, :placeid, :price_level, :open_now, :periods, :radius, :weekday_text

  def initialize(lat, lon, radius=1609)
    @lat = lat
    @lon = lon
    @radius = radius
    @rating = "No rating available"
    @price_level = "Not available"
    @has_error = false
    parse_nearby_restaurants

  end

  def call_google_places_api(url)

    json_response = HTTParty.get(url).body
    return JSON.parse( json_response )
  end

  def parse_nearby_restaurants

    restaurants = Hash.new()

    #do a places search to get the name of restaurants and their place_id within a given radius
    #search_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="+ @lat + "," + @lon + "&radius=1000&types=food&key=AIzaSyB3xKb4v0cK805_F1ApSX0Os0KS-XzDoO4"
    search_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurants&location=" + @lat.to_s + "," + @lon.to_s + "&radius=" + @radius.to_s + "&types=restaurant&key=" + ENV["GOOGLE_PLACES"]
    #search_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurants&location=" + @lat.to_s + "," + @lon.to_s + "&radius=" + @radius.to_s + "&types=restaurant&key=AIzaSyBWIRHm8UOx8VLKT5x13thHOO-2O0HtJKs"


    parsed_result = call_google_places_api(search_url)

    #pp parsed_result

    parsed_result['results'].each do |result|

      restaurants[result['name']] = result['place_id']

    end

    place_id = restaurants[restaurants.keys.sample]
    if place_id.nil?
      @has_error = true
    else

      puts "IN NEW ELSE"
      #do a details search to retrieve details about the selected location
      details_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + place_id + "&key=" + ENV["GOOGLE_PLACES"]
      #details_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + place_id + "AIzaSyBWIRHm8UOx8VLKT5x13thHOO-2O0HtJKs"

      details_result = call_google_places_api(details_url)

      #pp details_result

      if details_result['result']['formatted_address'] != nil
        @address = details_result['result']['formatted_address']
      end

      #THINK ABOUT REMOVING THIS:
      if details_result['result']['place_id'] != nil
        @placeid = details_result['result']['place_id']
      end

      if details_result['result']['formatted_phone_number'] != nil
        @phone_number = details_result['result']['formatted_phone_number']
      end

      if details_result['result']['name'] != nil
        @name = details_result['result']['name']
      end

      if  details_result['result']['rating'] != nil
        @rating = details_result['result']['rating']
      end

      if  details_result['result'].include? "price_level" #&& details_result['result']['price_level'] != nil
        @price_level = details_result['result']['price_level']
        @price_level = "$" * @price_level
      end

      if details_result['result'].include? "opening_hours" #&& details_result['result']['opening_hours']['open_now'] != nil

        if details_result['result']['opening_hours']['open_now'] == true
          @open_now = "Open now"
        else
          @open_now = "Closed"
        end

        if details_result['result']['opening_hours']['periods'][Time.now.wday] != nil
          @periods = details_result['result']['opening_hours']['periods'][Time.now.wday]
          @periods = Time.parse(@periods['open']['time'].insert(2,":")).strftime("%I:%M%p")+ " - " + Time.parse(@periods['close']['time'].insert(2,":")).strftime("%I:%M%p")
        end
        @weekday_text =  details_result['result']['opening_hours']['weekday_text']
        #example: https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJIZtG1mlaQIgR6gd0v9uNliE&key=AIzaSyB3xKb4v0cK805_F1ApSX0Os0KS-XzDoO4
      end
    end
  end

  def has_error
    return @has_error
  end
end

def self.registered(app)

app.get '/' do
   File.read("public/app/index.html")
end

app.get "/.well-known/acme-challenge/:id" do
  "CqD-ZW-Uqkj3u0HwalQnMURLuymOXJXPLpGCqreyl3I.-UoHTrge-mXXavQ8aYtOhEYdvB2ZXHoqKXfHqlwppnc"
end

app.get '/places/:error' do

  @error = params[:error]

  erb :restaurant

end

app.get '/places' do
  lat = params[:lat]
  lon = params[:lon]

   @place = Places.new(lat, lon, )
  #
  # @weather = Weathers.new(lat,lon)
  #
  # erb :restaurant
  # "Coords: " + lat + lon
  # @place.to_json

  puts "======================"


  puts

  h = {}
  if @place.has_error
    h['error'] = true;
  else

    @place.instance_variables.each { |var| h[var.to_s.delete("@").to_sym] = @place.instance_variable_get(var)}
    #puts @place.instance_variables
    #print h
    puts
    puts @place.open_now

  end
  puts "======================"
  content_type :json

  #{:name => @place.name, :rating => @place.rating, :phone => @place.phone_number, :address => @place.address}.to_json
  #Hash[*@place.instance_variables.map{ |var| [var.to_s.delete("@").to_sym, @place.instance_variable_get(var)]}.flatten].to_json
  h.to_json
end

app.post '/places' do

  @json = JSON.parse(request.body.read)
  puts "IN PLACES"
  print @json
  puts


  query = @json["locationInput"]
  radius = @json["radius"]


  radius = radius.to_i * 1609

  puts "radius:" + radius.to_s
  puts "query: " + query

  puts "before IF in post places"

  if query.empty?
    lat = params[:lat]
    lon = params[:lon]

    puts lat
    puts lon

    @place = Places.new(lat, lon, radius)
    @weather = Weathers.new(lat,lon)

  else

    puts "INELSE " + query

    settings = Maps.new(query)
    settings.get_position

    puts settings.lat
    puts settings.lon

    @place = Places.new(settings.lat, settings.lon, radius)
    @weather = Weathers.new(settings.lat, settings.lon)

  end

  content_type :json

  #move to own method
  h = {}
  @place.instance_variables.each { |var| h[var.to_s.delete("@").to_sym] = @place.instance_variable_get(var)}

  h.to_json
end




end

    end
    end
end