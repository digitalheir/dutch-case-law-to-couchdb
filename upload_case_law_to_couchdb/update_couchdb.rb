require 'nokogiri'
require 'json'
require 'open-uri'
require 'base64'
require_relative 'couch'

RES_MAX=1000

TO_HTML = Nokogiri::XSLT(File.open('xslt/rechtspraak_to_html.xslt'))

def get_rechtspraak_html(xml)
  html = TO_HTML.transform(xml)

  # puts html.to_s
  html.to_s
end

def is_about_this(about, ecli)
  !about or
      about.strip.length <= 0 or
      about.strip == "http://deeplink.rechtspraak.nl/uitspraak?id=#{ecli}"
end

def set_http_prefix(property)
  property
  .gsub('http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'rdf:')
  .gsub("http://www.w3.org/2000/01/rdf-schema#", 'rdfs:')
  .gsub('http://purl.org/dc/terms/', 'dcterms:')
  .gsub('http://psi.rechtspraak.nl/', 'psi:')
  .gsub('bwb-dl', 'bwb:')
  .gsub('https://e-justice.europa.eu/ecli', 'ecli:')
  .gsub('http://decentrale.regelgeving.overheid.nl/cvdr/', 'cvdr:')
  .gsub('http://publications.europa.eu/celex/', 'eu:')
  .gsub('http://tuchtrecht.overheid.nl/', 'tr:')
end

def add_metadata(doc, ecli, n_xml)
  n_xml.xpath('/metalex:root/metalex:mcontainer/metalex:meta',
              {'metalex' => 'http://www.metalex.eu/metalex/1.0'}).each do |meta|
    if is_about_this(meta['about'], ecli)
      property = set_http_prefix(meta['property'])
      doc[property] = meta['content']
    end

  end

  doc['@context'] = "http://rechtspraak.lawly.nl/rechtspraak.jsonld"
  doc['@id']= "http://deeplink.rechtspraak.nl/uitspraak?id=#{ecli}"
end

def get_new_doc(ecli, rev, attachments)
  doc = {
      _id: ecli
  }
  if rev
    doc[:_rev]= rev
  end

  xml = open("http://dutch-case-law.herokuapp.com/doc/#{ecli}").read.force_encoding('utf-8')

  n_xml = Nokogiri::XML xml
  add_metadata(doc, ecli, n_xml)
  expression_time = doc['dcterms:modified']


  unless attachments
    attachments = {}
  end
  doc['_attachments'] = attachments
  doc['_attachments'][expression_time] = {
      content_type: 'text/xml',
      data: Base64.encode64(xml)
  }
  # TODO do something about xml:preserve space... a bunch of &nbsp;s?
  doc['_attachments']['show.html'] = {
      content_type: 'text/html',
      data: Base64.encode64(get_rechtspraak_html(n_xml))
  }

  doc
end

def process_eclis(keys, expressions_map)
  bulk = []

  docs = Couch::LAWLY_CONNECTION.get_all_docs('rechtspraak', {:keys => keys.to_json})

  # Update existing docs
  existing_docs = {}
  docs.each do |doc|
    ecli=doc['_id']
    existing_docs[ecli] = true

    doc = get_new_doc(ecli, doc['_rev'], doc['_attachments'])
    bulk << doc
  end

  # Process new docs
  keys.each do |ecli|
    unless existing_docs[ecli]
      doc = get_new_doc(ecli, nil, nil)
      bulk << doc
    end
  end

  Couch::LAWLY_CONNECTION.flush_bulk_throttled('rechtspraak', bulk)
end


new_expressions = {}
from = 0
loop do
  uri = URI.parse('http://dutch-case-law.herokuapp.com/search')
  uri.query = URI.encode_www_form({
                                      max: RES_MAX,
                                      from: from,
                                      # modified: ["2014-09-25"]
                                  })
  puts "Opening #{uri.to_s}"
  data = JSON.parse open(uri).read
  if data and data['docs'].length > 0
    data['docs'].each do |doc|
      new_expressions[doc['id']]=doc
    end
  else
    break
  end

  if new_expressions.length >= 1000 #TODO
    break
  end
  from += RES_MAX
end

update_keys = []
new_expressions.each do |ecli, _|
  update_keys << ecli
  if update_keys.length >= 10
    process_eclis update_keys, new_expressions
    puts "Processed #{update_keys.length} keys"
    update_keys.clear

    break #TODO
  end
end

