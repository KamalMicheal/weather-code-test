require 'services/weather_service'

module V1
  class WeatherController < ApplicationController
    before_action :validate_index_params, only: :index

    def index
      location, lon, lat = params
      weather_service = WeatherService.new
      weather_details = weather_service.get_weather_details(location:, lon:, lat:)

      render json: weather_details.to_json, status: 200
    rescue => e
      render json: { response: e.message }, status: 500
    end

    private

    def validate_index_params
      unless params[:location].present? && params[:lon].present? && params[:lat].present?
        render json: { error: 'Invalid parameters - required location, lon, lat' }, status: :unprocessable_entity
      end
    end
  end
end
