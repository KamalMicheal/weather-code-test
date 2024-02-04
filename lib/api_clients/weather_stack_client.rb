require_relative 'weather_client'

class WeatherStackClient < WeatherClient
  private

  def fetch_weather_details(location:, **)
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

  def get_wind_speed_from_response(response_body)
    response_body['current']['wind_speed']
  end

  def get_temperature_from_response(response_body)
    response_body['current']['temperature']
  end

  def provider_name
    'WeatherStack'
  end

  def base_url
    ENV['WEATHER_STACK_BASE_URL']
  end

  def generate_cache_key(location:, **)
    "#{provider_name}-#{location}"
  end
end
