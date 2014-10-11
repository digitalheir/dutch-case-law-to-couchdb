require 'sinatra'
require 'open-uri'
require 'erb'
require 'coffee-script'
require 'tilt'
require 'net/http'
require 'nokogiri'
require_relative 'converter/xml_converter'
require_relative 'couch/rechtspraak_expression'
require 'json'

ATOM_PREFIXES = {:atom => 'http://www.w3.org/2005/Atom'}

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
  xml = get_rechtspraak_xml ecli
  conv = XmlConverter.new(ecli, xml)

  content_type 'application/ld+json'
  conv.metadata.to_json_ld.to_json
end

get '/ecli/:ecli' do
  ecli = params[:ecli]
  xml = get_rechtspraak_xml ecli
  expression = RechtspraakExpression.new(ecli, xml)
  expression.converter.generate_html(expression.doc)

  expression.converter.html_show
end

get "/js/search.js" do
  content_type "text/javascript"
  coffee :search
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

def parse_search_doc(entry)
#   <entry>
#     <id>ECLI:NL:RBARN:1999:AA1000</id>
#     <title type="text">ECLI:NL:RBARN:1999:AA1000, Rechtbank Arnhem, 24-09-1999, 05.072594.99</title>
#     <summary type="text">-</summary>
#     <updated>2013-04-04T15:31:25+02:00</updated>
#     <link rel="alternate" type="text/html" href="http://uitspraken.rechtspraak.nl/inziendocument?id=ECLI:NL:RBARN:1999:AA1000" />
#   </entry>
  doc={}
  entry.xpath('./atom:id', :atom => 'http://www.w3.org/2005/Atom').each do |id_tag|
    doc[:id] = id_tag.text
  end
  entry.xpath('./atom:title', :atom => 'http://www.w3.org/2005/Atom').each do |tag|
    doc[:title] = tag.text
  end
  entry.xpath('./atom:summary', :atom => 'http://www.w3.org/2005/Atom').each do |tag|
    doc[:summary] = tag.text
  end
  entry.xpath('./atom:updated', :atom => 'http://www.w3.org/2005/Atom').each do |tag|
    doc[:updated] = tag.text
  end
  entry.xpath('./atom:link', :atom => 'http://www.w3.org/2005/Atom').each do |tag|
    link = {}
    link[:rel] = tag['rel']
    link[:href] = tag['href']
    link[:type] = tag['type']
    doc[:link] = link
  end
  doc
end


def get_search_response params
  response = {}

  uri = URI.parse "http://data.rechtspraak.nl/uitspraken/zoeken"

  params_extractor = ParamsExtractor.new(params)
  uri.query = URI.encode_www_form(params_extractor.query_params)


  # ?
  res = Net::HTTP.get_response(uri)

  docs = []
  total = nil
  id=nil
  if res.is_a?(Net::HTTPSuccess)
    xml = Nokogiri::XML res.body
    subtitle_tags = xml.xpath('/atom:feed/atom:subtitle', ATOM_PREFIXES)
    if subtitle_tags.length > 0
      total = subtitle_tags.first.text.match(/([0-9]*)\s*\.?\s*$/)[1].to_i
    end
    xml.xpath('/atom:feed/atom:id', ATOM_PREFIXES).each do |id_tag|
      id = id_tag.text
    end
    xml.xpath('/atom:feed/atom:entry', ATOM_PREFIXES).each do |entry|
      doc = parse_search_doc(entry)
      docs << doc
    end
    error = nil
  else
    error = "Could not open URL #{uri.to_s}"
  end

  if params_extractor.error or error
    response[:error] = error
  else
    if id
      response[:id]=id
    end
    response[:max] = params_extractor.max
    response[:from] = params_extractor.from
    add_to_if_exists response, total, 'total'
    response[:return] = params_extractor.return_type
    add_to_if_exists response, params_extractor.replaces, 'replaces'
    add_to_if_exists response, params_extractor.date, 'date'
    add_to_if_exists response, params_extractor.modified, 'modified'
    add_to_if_exists response, params_extractor.type, 'type'
    add_to_if_exists response, params_extractor.subject, 'subject'

    response[:docs] = docs
  end
  response
end

get '/search' do
  response = get_search_response(params)
  content_type 'application/json'
  response.to_json
end

def add_to_if_exists(response, value, key)
  if value
    response[key]=value
  end
end

get '/' do
  erb :index
end
# get '/*' do
#   redirect to('https://github.com/digitalheir/dutch-case-law-to-metalex')
# end

# noinspection RubyTooManyInstanceVariablesInspection
class ParamsExtractor
  attr_reader :query_params
  attr_reader :return_type
  attr_reader :from
  attr_reader :replaces
  attr_reader :date
  attr_reader :modified
  attr_reader :type
  attr_reader :subject
  attr_reader :max
  attr_reader :error

  def initialize(params)
    @params=params
    @query_params={}
    @max, @error = get_max params[:max]

    @return_type = get_return params[:return]
    @from = get_from(params[:from])
    get_sort(params[:sort])
    @replaces = get_param('replaces', params[:replaces])
    @date = get_date_param('date', params[:date])
    @modified = get_date_param('modified', params[:modified])
    @type = get_type(params[:type])
    @subject = get_param('subject', params[:subject])
  end

  def get_max s_max
    if s_max
      max = s_max.to_i
    else
      max = 1000
    end
    error=nil
    if max > 1000 or max < 1
      error = "Return limit needs to be a number between 1 and 1000 inclusive"
    end
    @query_params[:max]=max
    return max, error
  end

  def get_return s_return
    if s_return and s_return.match /meta/i
      return_type = 'META'
    else
      return_type = 'DOC'
    end
    # return_statement =''
    if return_type=='DOC'
      @query_params[:return]='DOC'
    end

    return_type
  end

  def get_date_param param, value
    begin
      if value
        dates = JSON.parse value
        if dates.length > 0
          @query_params[param] = dates
        end
      end
    end
  end

  def get_param param, value
    if value
      @query_params[param]=value
      value
    else
      nil
    end
  end

  def get_type s
    if s
      if s.match /Conclusie/i
        type= 'Conclusie'
      elsif s.match /Uitspraak/i
        type= 'Uitspraak'
      else
        # TODO return error object
        type = 'Uitspraak'
      end
      @query_params['type', type]
      return type
    end
    nil
  end


  def get_sort(s_sort)
    sort = 'ASC'
    if s_sort and s_sort.match /DESC/i
      sort = 'DESC'
    end
    @query_params[:sort]=sort
    sort
  end

  def get_from(s_from)
    from = 0
    if s_from
      from = s_from.to_i
    end

    if from < 0
      from = 0
    end
    @query_params[:from]=from
    from
  end

end

