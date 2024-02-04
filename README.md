# Weather Service

## Task
Create an HTTP Service that reports on Melbourne weather. This service will source its information from either of the below providers:

## How to run
### Locally

To run the application locally, follow the following procedure

#### Install Ruby
You can use several tools to install ruby. This [page](https://www.ruby-lang.org/en/documentation/installation/) describes how to use major package management systems and third-party tools for managing and installing Ruby and how to build Ruby from source. The application was devloped and tested for ruby version 3.2.0.

#### Install RubyGem
RubyGems is a package management framework for Ruby. This [page](https://rubygems.org/pages/download) describes how to install rubygems.

#### Install bundler
Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed. To install bundler, use this command

    gem install bundler

## Installation instructions
Install the required gems by running the following command:

    bundle install

## Testing instructions
RSpec is used for testing. Run the following command to test the application

    bundle exec rspec --format doc

Make sure all test are green before using the application.

## Usage instructions

Copy `.env.template` to `.env.development.local` and update the following api keys
```
WEATHER_STACK_API_KEY
OPEN_WEATHER_MAP_API_KEY
```

Run the following command to start Rails Server
```
bundle exec rails s
```

Now, open this link in your browser to get the weather details in Melbourne
http://127.0.0.1:3000/v1/weather?location=melbourne&lon=144.94&lat=-37.84

### Query parameters
| attribute | description |
|-----------|-------------|
| location  | location name to get temperature for (ex: melbourne) |
| lon       | Longitude (ex: 144.94) |
| lat       | Latitude (ex: -37.84) |

Currently there is no validation to ensure that `lon` and `lat` belong to the `location`

## Design

This rails app contains one controller `WeatherController` with one action `index`.

I decided to use Template design pattern to be able to easily add more weather providers but simply inheriting the base class `WeatherClient` and define all required methods (check `WeatherStackClient`)

## Notes
For Weatherstack, they don't allow https for free subscriptions. This is why `WEATHER_STACK_BASE_URL = 'http://api.weatherstack.com'` in the config file uses http protocol (bad for security but ok for a code test)