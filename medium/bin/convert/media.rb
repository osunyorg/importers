class Media
  FILE = './converted/medias.json'

  attr_reader :url, :id

  def self.for(url)
    new(url).to_s
  end

  def initialize(url)
    @url = url
    clean_url
  end

  def to_s
    find_in_file || create
    id
  end

  protected

  def clean_url
    @url = url.gsub('/max/800', '')
  end

  def find_in_file
    return false unless data.has_key?(url)
    @id = data[url]
    puts "Id: #{id} found in file for #{url}"
    true
  end

  def create
    create_with_api
    save_to_file
  end
  
  def create_with_api
    puts "Creating media for #{url}"
    api = OsunyApi::ApiClient.new
    data = {
      body: {
        url: url
      },
      header_params: api.config.api_key,
      return_type: 'Object'
    }
    sleep 5
    response_body, response_code, response_headers = api.call_api('POST', '/communication/medias', data)
    @id = response_body[:id]
  end

  def save_to_file
    data[url] = id
    File.write(FILE, data.to_json)
  end

  def data
    @data ||= File.exist?(FILE) ? JSON.parse(File.open(FILE).read) : {}
  end
end