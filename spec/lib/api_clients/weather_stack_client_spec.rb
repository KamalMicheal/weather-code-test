require 'rails_helper'
require 'webmock/rspec'

require 'api_clients/weather_stack_client'

RSpec.describe WeatherStackClient do
  let(:base_url)   { "#{ENV['WEATHER_STACK_BASE_URL']}/#{ENV['WEATHER_STACK_URL_PATH']}" }
  let(:access_key) { ENV['WEATHER_STACK_API_KEY'] }
  let(:units)      { ENV['WEATHER_STACK_UNITS'] }

  let(:weather_stack_client) { WeatherStackClient.new }

  let(:request_url) do
    "#{base_url}"\
      "?access_key=#{access_key}"\
      "&units=#{units}"\
      "&query=#{default_location}"
  end

  let(:request_url_secondary_location) do
    "#{base_url}"\
      "?access_key=#{access_key}"\
      "&units=#{units}"\
      "&query=#{secondary_location}"
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

    context('with successful response from WeatherStack') do
      let(:default_location) { 'Melbourne' }
      let(:wind_speed) { 15 }
      let(:temperature) { 20 }

      let(:response_body) { { current: { wind_speed:, temperature: } }.to_json }

      before(:each) do
        stub_request(:get, request_url)
          .to_return(
            status: 200,
            headers: { content_type: 'application/json' },
            body: response_body
          )
      end

      subject { weather_stack_client.get_weather_details(location: default_location) }

      it('return includes wind_speed') do
        expect(subject.wind_speed).to eq(wind_speed)
      end

      it('return includes temperature_degrees') do
        expect(subject.temperature_degrees).to eq(temperature)
      end
    end

    context('with unsuccessful response from WeatherStack') do
      let(:default_location) { 'Melbourne' }
      before(:each) do
        stub_request(:get, request_url)
          .to_return(status: 500)
      end

      it('raises an exception') do
        expect { weather_stack_client.get_weather_details(location: default_location) }.to raise_error(RuntimeError)
      end
    end

    context('with invalid response body from WeatherStack') do
      let(:default_location) { 'Melbourne' }

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
        expect { weather_stack_client.get_weather_details(location: default_location) }.to raise_error(NoMethodError)
      end
    end

    context('caches the response for 3 seconds for ths same location') do
      let(:default_location) { 'Melbourne' }
      let(:wind_speed) { 15 }
      let(:temperature) { 20 }

      let(:response_body) { { current: { wind_speed:, temperature: } }.to_json }

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
        weather_stack_client.get_weather_details(location: default_location)

        Timecop.travel(freeze_time + 1.seconds)
        weather_stack_client.get_weather_details(location: default_location)

        expect(@stub).to have_been_requested.once

        Timecop.travel(freeze_time + 4.seconds)
        weather_stack_client.get_weather_details(location: default_location)

        expect(@stub).to have_been_requested.twice

        Timecop.return
      end
    end

    context('caches the response for 3 seconds for ths same location') do
      let(:default_location) { 'Melbourne' }
      let(:secondary_location) { 'Sydney' }
      let(:wind_speed) { 15 }
      let(:temperature) { 20 }

      let(:response_body) { { current: { wind_speed:, temperature: } }.to_json }

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
        weather_stack_client.get_weather_details(location: default_location)

        Timecop.travel(freeze_time + 1.seconds)
        weather_stack_client.get_weather_details(location: secondary_location)

        expect(@stub).to have_been_requested.once
        expect(@stub_secondary_location).to have_been_requested.once

        Timecop.return
      end
    end
  end
end
