class WeatherClient
  def initialize
    @connection = Faraday.new(base_url) do |f|
      f.response :json
    end
  end

  def get_weather_details(location: nil, lon: nil, lat: nil)
    cache_key = generate_cache_key(location:, lon:, lat:)

    Rails.cache.fetch(cache_key, expires_in: caching_expiry) do
      weather_details_response = fetch_weather_details(location:, lon:, lat:)

      raise "unable to fetch data from #{provider_name}" unless weather_details_response.success?

      generate_weather_details(weather_details_response.body)
    end
  end

  private

  def fetch_weather_details(**)
    raise 'Method not implemented'
  end

  def generate_weather_details(response_body)
    WeatherDetails.new(
      wind_speed: get_wind_speed_from_response(response_body),
      temperature_degrees: get_temperature_from_response(response_body)
    )
  rescue NoMethodError => e
    raise NoMethodError, "error parsing #{provider_name} response", e.backtrace.join('\n')
  end

  def get_wind_speed_from_response(**)
    raise 'Method not implemented'
  end

  def get_temperature_from_response(**)
    raise 'Method not implemented'
  end

  def base_url
    raise 'Method not implemented'
  end

  def provider_name
    raise 'Method not implemented'
  end

  def caching_expiry
    3.seconds
  end

  def generate_cache_key(**)
    raise 'Method not implemented'
  end
end
