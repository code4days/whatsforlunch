require './weathers'
require 'json'


class Places

  attr_reader :lat, :lon, :address, :phone_number, :name, :rating, :placeid, :price_level, :open_now, :periods, :radius, :weekday_text

  def initialize(lat, lon, radius=1609)
    @lat = lat
    @lon = lon
    @radius = radius
    @rating = "No rating available"
    @price_level = "Not available"

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
    search_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurants&location=" + @lat.to_s + "," + @lon.to_s + "&radius=" + @radius.to_s + "&types=restaurant&key=AIzaSyB3xKb4v0cK805_F1ApSX0Os0KS-XzDoO4"
    #search_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurants&location=" + @lat.to_s + "," + @lon.to_s + "&radius=" + @radius.to_s + "&types=restaurant&key=AIzaSyBWIRHm8UOx8VLKT5x13thHOO-2O0HtJKs"


    parsed_result = call_google_places_api(search_url)

    #pp parsed_result

    parsed_result['results'].each do |result|

      restaurants[result['name']] = result['place_id']

    end

    place_id = restaurants[restaurants.keys.sample]

    #do a details search to retrieve details about the selected location
    details_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + place_id + "&key=AIzaSyB3xKb4v0cK805_F1ApSX0Os0KS-XzDoO4"
    #details_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=" + place_id + "AIzaSyBWIRHm8UOx8VLKT5x13thHOO-2O0HtJKs"

    details_result = call_google_places_api(details_url)

    pp details_result

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

get '/places/:error' do

  @error = params[:error]

  erb :restaurant

end

get '/places' do
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
  @place.instance_variables.each { |var| h[var.to_s.delete("@").to_sym] = @place.instance_variable_get(var)}
  #puts @place.instance_variables
  #print h
  puts
  puts @place.open_now
  puts "======================"
  content_type :json

  print @place.weekday_text
  puts
  print h[:weekday_text]

  #{:name => @place.name, :rating => @place.rating, :phone => @place.phone_number, :address => @place.address}.to_json
  #Hash[*@place.instance_variables.map{ |var| [var.to_s.delete("@").to_sym, @place.instance_variable_get(var)]}.flatten].to_json
  h.to_json
end


post '/places' do

  puts "IN PLACES"

  query = params[:locationinput]
  radius = params[:radius]

  puts radius.class
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
    puts settings.lat
    puts settings.lon

    @place = Places.new(settings.lat, settings.lon, radius)
    @weather = Weathers.new(settings.lat, settings.lon)

  end

  erb :restaurant

end
