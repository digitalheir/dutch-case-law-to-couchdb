require 'sinatra'
require 'open-uri'
require 'erb'
require 'coffee-script'
require 'tilt'
require 'net/http'
require 'nokogiri'
require_relative 'converter/xml_converter'
require_relative 'rechtspraak_search_parser'
require_relative 'couch/rechtspraak_expression'
require 'json'
include RechtspraakSearchParser


get '/doc' do
  redirect to('/')
end

get '/example' do
  expression = RechtspraakExpression.new("example", Nokogiri::XML(File.read('converter/example_rechtspraak_doc.xml')), true)
  expression.converter.generate_html(expression.doc)

  expression.converter.html_show
end

get '/jurisdiction' do
  #TODO list jurisdictions
end

get '/jurisdiction/:id' do
  #TODO get all info for jurisdiction
end

def get_rechtspraak_xml ecli, return_type='DOC'
  uri = URI("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}&return=#{return_type}")
  res = Net::HTTP.get_response(uri)

  if res.is_a?(Net::HTTPSuccess)
    Nokogiri::XML res.body
  else
    raise "Could not open #{uri}"
  end
end

get '/id/:ecli' do
  ecli = params[:ecli].sub(/(:META|:DOC)$/,'')
  if ecli == 'example'
    xml = Nokogiri::XML(File.read('converter/example_rechtspraak_doc.xml'))
  else
  xml = get_rechtspraak_xml ecli
  end
  conv = XmlConverter.new(ecli, xml)

  content_type 'application/ld+json'
  conv.get_json_ld.to_json
end

get '/ecli/:ecli' do
  ecli = params[:ecli]
  xml = get_rechtspraak_xml ecli
  # TODO don't convert to metalex first... It doesn't add anything
  expression = RechtspraakExpression.new(ecli, xml)
  expression.converter.generate_html(expression.doc)

  expression.converter.html_show
end

get "/js/search.js" do
  content_type "text/javascript"
  coffee :search
end

get '/search.json' do
    response = get_search_response(params)
    content_type 'application/json'
    response.to_json
end

get '/search' do
  q = params[:q] || ''
  erb :search, {:locals => {:initial_value => q}}
end

# Open given ECLI on rechtspraak.nl, convert to Metalex, return converted
get '/doc/:ecli' do
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

    converter = XmlConverter.new(ecli, xml)
    converter.convert_to_metalex
    converted = converter.metalex
    status 200
    content_type 'text/xml'
    converted.to_s
  else
    # raise Sinatra::NotFound
    status 404
    content_type 'text/xml'

    '<?xml version="1.0" encoding="utf-8"?><error>Could not find ECLI '+params[:ecli]+'</error>'
  end
end







get '/' do
  erb :index
end
# get '/*' do
#   redirect to('https://github.com/digitalheir/dutch-case-law-to-metalex')
# end



