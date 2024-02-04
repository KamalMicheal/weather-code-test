# frozen_string_literal: true

require 'rails_helper'
require 'services/weather_service'

RSpec.describe 'V1::Weathers', type: :request do
  describe 'GET /' do
    let(:valid_weather_details) { WeatherDetails.new(wind_speed: 12, temperature_degrees: 345) }

    describe 'input validation' do
      before do
        allow_any_instance_of(WeatherService)
          .to receive(:get_weather_details)
          .and_return(valid_weather_details)
      end

      it 'validates presence of location' do
        get '/v1/weather?lon=12&lat=344'

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'validates presence of lon' do
        get '/v1/weather?location=melbourne&lat=344'

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'validates presence of lat' do
        get '/v1/weather?location=melbourne&lon=12'

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns valid response with all required params present' do
        get '/v1/weather?location=melbourne&lon=12&lat=344'

        expect(response).to have_http_status(:success)
        expect(response.body).to eq(valid_weather_details.to_json)
      end
    end

    context 'when WeatherService raises an error' do
      before do
        allow_any_instance_of(WeatherService)
          .to receive(:get_weather_details)
          .and_raise(StandardError)
      end

      it 'validates presence of lat' do
        get '/v1/weather?location=melbourne&lon=12&lat=344'

        expect(response).to have_http_status(:server_error)
      end
    end
  end
end
