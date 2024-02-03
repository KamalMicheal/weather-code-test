require 'faraday'

class WeatherStackClient
  def initialize
    @connection = Faraday.new(ENV['WEATHER_STACK_BASE_URL']) do |f|
      f.response :json
    end
  end

  def get_weather_details(location:, **)
    Rails.cache.fetch("#{cache_key}-#{location}", expires_in: 3.seconds) do
      weather_details_response = fetch_weather_details(location)

      raise 'unable to fetch data from WeatherStack' unless weather_details_response.success?

      generate_weather_details(weather_details_response.body)
    end
  end

  private

  def fetch_weather_details(location)
    @connection.get(
      ENV['WEATHER_STACK_URL_PATH'],
      {
        access_key: ENV['WEATHER_STACK_API_KEY'],
        units: ENV['WEATHER_STACK_UNITS'],
        query: location
      }
    )
  rescue => e
    raise 'unable to fetch data from WeatherStack provider', e
  end

  def generate_weather_details(response_body)
    WeatherDetails.new(
      wind_speed: get_wind_speed_from_response(response_body),
      temperature_degrees: get_temperature_from_response(response_body)
    )
  rescue NoMethodError => e
    raise NoMethodError, 'error parsing OpenWeatherMap response', e.backtrace.join('\n')
  end

  def get_wind_speed_from_response(response_body)
    response_body['current']['wind_speed']
  end

  def get_temperature_from_response(response_body)
    response_body['current']['temperature']
  end

  def cache_key
    'WeatherStack'
  end
end
