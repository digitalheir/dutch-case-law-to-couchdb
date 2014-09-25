require 'sinatra'
require 'open-uri'
require 'net/http'
require 'nokogiri'
require_relative 'metalex_converter/rechtspraak_to_metalex_converter'
require 'json'

MAPPING = JSON.parse open('metalex_converter/rechtspraak_mapping.json').read
CONVERTER = RechtspraakToMetalexConverter.new(MAPPING)
ATOM_PREFIXES = {:atom => 'http://www.w3.org/2005/Atom'}

# Open given ECLI on rechtspraak.nl, convert to Metalex, return converted
get '/doc' do
  redirect to('https://github.com/digitalheir/dutch-case-law-to-metalex')
end

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
    converted = CONVERTER.start(xml, ecli)
    status 200
    content_type 'application/xml'
    converted.to_s
  else
    # raise Sinatra::NotFound
    status 404
    content_type 'application/xml'

    '<?xml version="1.0" encoding="utf-8"?><error>Could not find ECLI '+params[:ecli]+'</error>'
  end

end

get '/' do
  redirect to('https://github.com/digitalheir/dutch-case-law-to-metalex')
end

def parse_doc(entry)
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

def get_max s_max, query_params
  if s_max
    max = s_max.to_i
  else
    max = 1000
  end
  error=nil
  if max > 1000 or max < 1
    error = "Return limit needs to be a number between 1 and 1000 inclusive"
  end
  query_params[:max]=max
  return max, error
end

def get_return s_return, query_params
  if s_return and s_return.match /meta/i
    return_type = 'META'
  else
    return_type = 'DOC'
  end
  return_statement =''
  if return_type=='DOC'
    query_params[:return]='DOC'
  end

  return_type
end

def get_date_param param, value, query_params
  begin
    if value
      dates = JSON.parse value
      if dates.length > 0
        query_params[param] = dates
      end
    end
  end
end

def get_param param, value, query_params
  if value
    query_params[param]=value
    value
  else
    nil
  end
end

def get_type s, query_params
  if s
    if s.match /Conclusie/i
      type= 'Conclusie'
    elsif s.match /Uitspraak/i
      type= 'Uitspraak'
    end
    query_params['type', type]
    return type
  end
  nil
end


def get_sort(s_sort, query_params)
  sort = 'ASC'
  if s_sort and s_sort.match /DESC/i
    sort = 'DESC'
  end
  query_params[:sort]=sort
  sort
end

def get_from(s_from, query_params)
  from = 0
  if s_from
    from = s_from.to_i
  end

  if from < 0
    from = 0
  end
  query_params[:from]=from
  from
end

def get_search_response params
  response = {}

  uri = URI.parse "http://data.rechtspraak.nl/uitspraken/zoeken"
  query_params = {}

  max, error = get_max params[:max], query_params

  return_type = get_return params[:return], query_params
  from = get_from(params[:from], query_params)
  get_sort(params[:sort], query_params)
  replaces = get_param('replaces', params[:replaces], query_params)
  date = get_date_param('date', params[:date], query_params)
  modified = get_date_param('modified', params[:modified], query_params)
  type = get_type(params[:type], query_params)
  subject = get_param('subject', params[:subject], query_params)

  uri.query = URI.encode_www_form(query_params)


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
      doc = parse_doc(entry)
      docs << doc
    end
  else
    error = "Could not open URL #{uri.to_s}"
  end

  if error
    response[:error] = error
  else
    if id
      response[:id]=id
    end
    response[:max] = max
    response[:from] = from
    response[:return] = return_type
    add_to_if_exists response, replaces, 'replaces'
    add_to_if_exists response, total, 'total'
    add_to_if_exists response, date, 'date'
    add_to_if_exists response, modified, 'modified'
    add_to_if_exists response, type, 'type'
    add_to_if_exists response, subject, 'subject'

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

get '/*' do
  redirect to('https://github.com/digitalheir/dutch-case-law-to-metalex')
end


