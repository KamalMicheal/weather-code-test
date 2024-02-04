require_relative 'weather_client'

class OpenWeatherMapClient < WeatherClient
  private

  def fetch_weather_details(lon:, lat:, **)
    @connection.get(ENV['OPEN_WEATHER_MAP_URL_PATH'],
                    {
                      appid: ENV['OPEN_WEATHER_MAP_API_KEY'],
                      units: ENV['OPEN_WEATHER_MAP_UNITS'],
                      lat:,
                      lon:
                    })
  rescue => e
    raise StandardError, 'unable to fetch data from OpenWeatherMap provider', e
  end

  def get_wind_speed_from_response(response_body)
    response_body['wind']['speed']
  end

  def get_temperature_from_response(response_body)
    response_body['main']['temp']
  end

  def provider_name
    'OpenWeatherMap'
  end

  def base_url
    ENV['OPEN_WEATHER_MAP_BASE_URL']
  end

  def generate_cache_key(lon:, lat:, **)
    "#{provider_name}-#{lon}-#{lat}"
  end
end
