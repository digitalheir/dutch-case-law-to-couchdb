require 'sinatra'
require 'open-uri'
require 'net/http'
require 'nokogiri'
require_relative 'metalex_converter/rechtspraak_to_metalex_converter'
require 'json'

MAPPING = JSON.parse open('metalex_converter/rechtspraak_mapping.json').read
CONVERTER = RechtspraakToMetalexConverter.new(MAPPING)

# Open given ECLI on rechtspraak.nl, convert to Metalex, return converted
get '/:ecli' do
  if params[:return] == 'META'
    return_type = 'META'
  else
    return_type = 'DOC'
  end

  ecli = params[:ecli]
  # Try to open this URL
  uri = URI("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}&return=#{return_type}")
  res = Net::HTTP.get_response(uri)

  if res.is_a?(Net::HTTPSuccess)
    xml=Nokogiri::XML res.body
    # The rechtspraak docs have metadata in them, but we want an XML doc out of the actual content. So first get the content root node.
    converted = CONVERTER.start(xml,ecli)
    status 200
    content_type 'application/xml'
    converted.to_s
  else
    # raise Sinatra::NotFound
    status 404
    content_type 'text/plain'
    "Could not find ECLI '#{params[:ecli]}'"
  end
end

