require 'sinatra'
require 'open-uri'
require 'net/http'
require 'nokogiri'
require_relative 'metalex_converter/rechtspraak_to_metalex_converter'
require 'json'

MAPPING = JSON.parse open('metalex_converter/rechtspraak_mapping.json').read
CONVERTER = RechtspraakToMetalexConverter.new(MAPPING)

# Open given ECLI on rechtspraak.nl, convert to Metalex, return converted
get 'ecli/:ecli' do
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
    content_type 'text/plain'
    "Could not find ECLI '#{params[:ecli]}'"
  end

end

get '/' do
  'hello world!'
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

get '/search' do
  response = {}
  error=nil
  if params[:max]
    max = params[:max].to_i
  else
    max = 1000
  end
  if max > 1000 or max < 1
    error = "Return limit needs to be a number between 1 and 1000 inclusive"
  end

  if params[:return] and params[:return].match /meta/i
    return_type = 'META'
  else
    return_type = 'DOC'
  end
  return_statement =''
  if return_type=='DOC'
    return_statement = "&return=DOC"
  end

  from = 0
  if params[:from]
    from = params[:from].to_i
  end

  if from < 0
    from = 0
  end

  uri = URI("http://data.rechtspraak.nl/uitspraken/zoeken?max=#{max}#{return_statement}&from=#{from}")
  res = Net::HTTP.get_response(uri)

  docs = []
  total = nil
  id=nil
  if res.is_a?(Net::HTTPSuccess)
    xml = Nokogiri::XML res.body

    subtitle_tags = xml.xpath('/atom:feed/atom:subtitle', :atom => 'http://www.w3.org/2005/Atom')
    if subtitle_tags.length > 0
      total = subtitle_tags.first.text.match(/([0-9]*)\s*\.?\s*$/)[1].to_i
    end

    xml.xpath('/atom:feed/atom:id', :atom => 'http://www.w3.org/2005/Atom').each do |id_tag|
      id = id_tag.text
    end

    xml.xpath('/atom:feed/atom:entry', :atom => 'http://www.w3.org/2005/Atom').each do |entry|
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
    if total
      response[:total] = total
    end
    response[:docs] = docs
  end
  response.to_json
end

