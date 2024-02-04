require 'api_clients/open_weather_map_client'
require 'api_clients/weather_stack_client'

class WeatherService
  def initialize(weather_clients: weather_clients_default_list)
    raise 'You need to provide at least one client' if weather_clients.empty?

    @weather_clients = weather_clients
  end

  def get_weather_details(location:, lon:, lat:)
    @weather_clients.each do |weather_client|
      weather_details = weather_client.get_weather_details(location:, lon:, lat:)

      write_cache(location:, lon:, lat:, weather_details:)

      return weather_details
    rescue => e
      Rails.logger.info "unable to fetch weather for #{weather_client.class.name}"
      Rails.logger.info e
    end

    # all clients fail at the point. try to read the recent value from the cache
    cached_weather_details = read_from_cache(location:, lon:, lat:)

    raise 'unable to fetch weather details', { location:, lon:, lat: } if cached_weather_details.nil?

    cached_weather_details
  end

  private

  def generate_cache_key(location:, lon:, lat:)
    @generate_cache_key ||= "#{location}-#{lon}-#{lat}"
  end

  def weather_clients_default_list
    [
      WeatherStackClient.new,
      OpenWeatherMapClient.new
    ]
  end

  def write_cache(location:, lon:, lat:, weather_details:)
    cache_key = generate_cache_key(location:, lon:, lat:)

    Rails.cache.write(cache_key, weather_details)
  end

  def read_from_cache(location:, lon:, lat:)
    cache_key = generate_cache_key(location:, lon:, lat:)

    Rails.cache.read(cache_key)
  end
end
