require 'rails_helper'
require 'webmock/rspec'

require 'api_clients/open_weather_map_client'

RSpec.describe OpenWeatherMapClient do
  let(:base_url)           { "#{ENV['OPEN_WEATHER_MAP_BASE_URL']}/#{ENV['OPEN_WEATHER_MAP_URL_PATH']}" }
  let(:appid)              { ENV['OPEN_WEATHER_MAP_API_KEY'] }
  let(:units)              { ENV['OPEN_WEATHER_MAP_UNITS'] }
  let(:default_location)   { { lon: 10.99, lat: 44.34 } }
  let(:secondary_location) { { lon: -33.86, lat: 151.21 } }
  let(:wind_speed)         { 15 }
  let(:temperature)        { 20 }

  let(:open_weather_map_client) { OpenWeatherMapClient.new }

  let(:request_url) do
    "#{base_url}"\
      "?appid=#{appid}"\
      "&units=#{units}"\
      "&lon=#{default_location[:lon]}"\
      "&lat=#{default_location[:lat]}"
  end

  let(:request_url_secondary_location) do
    "#{base_url}"\
      "?appid=#{appid}"\
      "&units=#{units}"\
      "&lon=#{secondary_location[:lon]}"\
      "&lat=#{secondary_location[:lat]}"
  end

  before(:all) do
    WebMock.enable!
  end

  after(:all) do
    WebMock.disable!
  end

  describe '#get_weather_details' do
    before(:each) do
      Rails.cache.clear
    end

    context('with successful response from OpenWeatherMap') do
      let(:response_body) do
        {
          main: { temp: temperature },
          wind: { speed: wind_speed }
        }.to_json
      end

      before(:each) do
        stub_request(:get, request_url)
          .to_return(
            status: 200,
            headers: { content_type: 'application/json' },
            body: response_body
          )
      end

      subject { open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat]) }

      it('return includes wind_speed') do
        expect(subject.wind_speed).to eq(wind_speed)
      end

      it('return includes temperature_degrees') do
        expect(subject.temperature_degrees).to eq(temperature)
      end
    end

    context('with unsuccessful response from OpenWeatherMap') do
      before(:each) do
        stub_request(:get, request_url)
          .to_return(status: 500)
      end

      it('raises an exception') do
        expect { open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat]) }.to raise_error(RuntimeError)
      end
    end

    context('with invalid response body from OpenWeatherMap') do
      let(:response_body) do
        {
          invalid: 'response'
        }.to_json
      end

      before(:each) do
        stub_request(:get, request_url)
          .to_return(
            status: 200,
            headers: { content_type: 'application/json' },
            body: response_body
          )
      end

      it('raises an exception') do
        expect {
          open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat])
        }.to raise_error(NoMethodError)
      end
    end

    context('caches the response for 3 seconds for ths same location') do
      let(:response_body) do
        {
          main: { temp: temperature },
          wind: { speed: wind_speed }
        }.to_json
      end

      let(:freeze_time) { Time.utc(2024, 1, 30, 12, 20, 30) }

      before(:each) do
        @stub = stub_request(:get, request_url)
                .to_return(
                  status: 200,
                  headers: { content_type: 'application/json' },
                  body: response_body
                )
      end

      it 'caches the response only for 3 seconds' do
        Timecop.freeze(freeze_time)
        open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat])

        Timecop.travel(freeze_time + 1.seconds)
        open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat])

        expect(@stub).to have_been_requested.once

        Timecop.travel(freeze_time + 4.seconds)
        open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat])

        expect(@stub).to have_been_requested.twice

        Timecop.return
      end
    end

    context('caches the response for 3 seconds for ths same location') do
      let(:response_body) do
        {
          main: { temp: temperature },
          wind: { speed: wind_speed }
        }.to_json
      end

      let(:freeze_time) { Time.utc(2024, 1, 30, 12, 20, 30) }

      before(:each) do
        @stub = stub_request(:get, request_url)
                .to_return(
                  status: 200,
                  headers: { content_type: 'application/json' },
                  body: response_body
                )

        @stub_secondary_location = stub_request(:get, request_url_secondary_location)
                                   .to_return(
                                     status: 200,
                                     headers: { content_type: 'application/json' },
                                     body: response_body
                                   )
      end

      it 'does not load from cache for new locations' do
        Timecop.freeze(freeze_time)
        open_weather_map_client.get_weather_details(lon: default_location[:lon], lat: default_location[:lat])

        Timecop.travel(freeze_time + 1.seconds)
        open_weather_map_client.get_weather_details(lon: secondary_location[:lon], lat: secondary_location[:lat])

        expect(@stub).to have_been_requested.once
        expect(@stub_secondary_location).to have_been_requested.once

        Timecop.return
      end
    end
  end
end
