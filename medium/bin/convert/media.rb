class Media
  FILE = './converted/medias.json'

  attr_reader :url, :id, :filename, :signed_id

  def initialize(url)
    @url = url
    clean_url
    find_in_file || create
  end

  def to_hash
    {
      id: id,
      filename: filename,
      signed_id: signed_id
    }
  end

  protected

  def clean_url
    @url = url.gsub('/max/800', '')
  end

  def find_in_file
    return false unless data.has_key?(url)
    media = data[url]
    @id = media['id']
    @filename = media['filename']
    @signed_id = media['signed_id']
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
    blob = response_body[:original_blob]
    @id = blob[:id]
    @filename = blob[:filename]
    @signed_id = blob[:signed_id]
  end

  def save_to_file
    data[url] = to_hash
    File.write(FILE, data.to_json)
  end

  def data
    @data ||= File.exist?(FILE) ? JSON.parse(File.open(FILE).read) : {}
  end
end