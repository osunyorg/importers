require 'json'
require 'bundler/setup'
require_relative 'convert/blocks'
require_relative 'convert/post'
require_relative 'convert/media'

Bundler.require(:default)
Dotenv.load

OsunyApi.configure do |config|
  config.api_key['X-Osuny-Token'] = ENV['OSUNY_API_TOKEN']
  config.host = ENV['OSUNY_API_HOST']
  config.base_path = '/api/osuny/v1'
  # config.debugging = true
end

SOURCE_DIRECTORY = './imported/'

def convert_id(id)
  puts "Convert id #{id}"
  convert_path "#{SOURCE_DIRECTORY}#{id}.html"
end

def convert_path(path)
  puts "Convert path #{path}"
  post = Post.new path
  puts JSON.pretty_generate(post.hash)
  File.write("converted/#{post.id}.json", post.hash.to_json)
end

def convert_directory
  puts "Convert directory"
  Dir["#{SOURCE_DIRECTORY}*.html"].each do |path|
    convert_path path
  end
end

ARGV.empty? ? convert_directory
            : convert_id(ARGV.first)