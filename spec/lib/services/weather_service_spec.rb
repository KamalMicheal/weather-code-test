# frozen_string_literal: true

require 'rails_helper'
require 'services/weather_service'
require 'api_clients/weather_client'

RSpec.describe WeatherService do
  let(:location)        { 'Melbourne' }
  let(:lon)             { 144.94 }
  let(:lat)             { -37.84 }
  let(:weather_details) { WeatherDetails.new(wind_speed: 12, temperature_degrees: 34) }

  before(:each) do
    Rails.cache.clear
  end

  context 'with one weather client' do
    let(:weather_client)  { instance_double(WeatherClient) }
    let(:weather_service) { WeatherService.new(weather_clients: [weather_client]) }

    context 'when client returns a valid response' do
      before do
        allow(weather_client).to receive(:get_weather_details).with(location:, lon:, lat:).and_return(weather_details)
      end

      let(:subject) { weather_service.get_weather_details(location:, lon:, lat:) }

      it 'returns a valid weather_details' do
        expect(subject).to eq(weather_details)
      end
    end

    context 'when client errors' do
      context 'when this request was not cached before' do
        before do
          allow(weather_client).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
        end

        it 'returns a valid weather_details' do
          expect do
            weather_service.get_weather_details(location:, lon:, lat:)
          end.to raise_error(StandardError)
        end
      end

      context 'when this request was cached before' do
        it 'loads from the existing cache' do
          allow(weather_client).to receive(:get_weather_details).with(location:, lon:, lat:).and_return(weather_details)
          expect(weather_service.get_weather_details(location:, lon:, lat:)).to eq(weather_details)

          allow(weather_client).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
          expect(weather_service.get_weather_details(location:, lon:, lat:)).to eq(weather_details)
        end
      end
    end
  end

  context 'with 2+ weather clients' do
    let(:weather_client_1)  { instance_double(WeatherClient) }
    let(:weather_client_2)  { instance_double(WeatherClient) }
    let(:weather_details_2) { WeatherDetails.new(wind_speed: 89, temperature_degrees: 65) }
    let(:weather_service)   { WeatherService.new(weather_clients: [weather_client_1, weather_client_2]) }

    context 'when the first client returns a valid response' do
      before do
        allow(weather_client_1).to receive(:get_weather_details).with(location:, lon:, lat:).and_return(weather_details)
        allow(weather_client_2).to receive(:get_weather_details).with(location:, lon:,
                                                                      lat:).and_return(weather_details_2)
      end

      let(:subject) { weather_service.get_weather_details(location:, lon:, lat:) }

      it 'returns a valid weather_details' do
        expect(subject).to eq(weather_details)
      end
    end

    context 'when the first client errors and the second returns a valid response' do
      before do
        allow(weather_client_1).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
        allow(weather_client_2).to receive(:get_weather_details).with(location:, lon:,
                                                                      lat:).and_return(weather_details_2)
      end

      let(:subject) { weather_service.get_weather_details(location:, lon:, lat:) }

      it 'returns a valid weather_details' do
        expect(subject).to eq(weather_details_2)
      end
    end

    context 'when both clients error' do
      context 'when this request was cached before' do
        before do
          allow(weather_client_2).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
        end

        it 'loads from the existing cache' do
          allow(weather_client_1).to receive(:get_weather_details).with(location:, lon:,
                                                                        lat:).and_return(weather_details)
          expect(weather_service.get_weather_details(location:, lon:, lat:)).to eq(weather_details)

          allow(weather_client_1).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
          expect(weather_service.get_weather_details(location:, lon:, lat:)).to eq(weather_details)
        end
      end

      context 'when this request was not cached before' do
        before do
          allow(weather_client_1).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
          allow(weather_client_2).to receive(:get_weather_details).with(location:, lon:, lat:).and_raise(StandardError)
        end

        it 'returns a valid weather_details' do
          expect do
            weather_service.get_weather_details(location:, lon:, lat:)
          end.to raise_error(StandardError)
        end
      end
    end
  end
end
