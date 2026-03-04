require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)
Dotenv.load

OsunyApi.configure do |config|
  config.api_key['X-Osuny-Token'] = ENV['OSUNY_API_TOKEN']
  config.host = ENV['OSUNY_API_HOST']
  config.base_path = '/api/osuny/v1'
  # config.debugging = true
end

API = OsunyApi::CommunicationWebsitePostApi.new
SOURCE_DIRECTORY = './converted/'

def export_id(id)
  puts "Export id #{id}"
  export_path "#{SOURCE_DIRECTORY}#{id}.json"
end

def export_path(path)
  puts "Export path #{path}"
  file = File.read path
  object = JSON.parse file
  data = {
    body: {
      posts: [
        object
      ]
    }
  }
  begin
    result = API.communication_websites_website_id_posts_upsert_post(ENV['OSUNY_WEBSITE_ID'], data)
  rescue OsunyApi::ApiError => e
    puts "Exception when calling CommunicationWebsitePostApi->communication_websites_website_id_posts_upsert_post: #{e}"
  end
end

def export_directory
  puts "Export directory"
  Dir["#{SOURCE_DIRECTORY}*.json"].each do |path|
    export_path path
  end
end

ARGV.empty? ? export_directory
            : export_id(ARGV.first)