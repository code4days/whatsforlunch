require 'sinatra'
#require 'sinatra/reloader' if development?
require 'httparty'
require 'pp'
require 'json'


require_relative 'routes/maps'
require_relative 'routes/places'
require_relative 'routes/weathers'

class BaseApp < Sinatra::Base
        configure do
            set :sessions, true
            use Rack::Session::Cookie, :key => 'rack.session',
                                    :domain => 'localhost',
                                    :path => '/',
                                    :expire_after => 2592000,
                                    :secret => 'M3ga8yt3 5tuff',
                                    :old_secret => 'M3ga8yt3 5tuff'
            set :views, 'views'
            set :public_folder, 'public/app'
            set :root, File.dirname(__FILE__)
        end

    # Print out what you are running
    puts "You are currently running: " + ENV['RACK_ENV']
  
  register Sinatra::Routing::Places
  register Sinatra::Routing::Maps
  register Sinatra::Routing::Weathers

end
