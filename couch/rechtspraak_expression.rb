class RechtspraakExpression
  attr_reader :doc
  attr_reader :converter
# Initializes a new CouchDB document for a case law expression.
# Only processes metadata; source docs are added in add_attachments.
  def initialize(ecli, original_xml, rich_markup=nil)
    @converter = XmlConverter.new(ecli, original_xml)

    @doc = {}
    add_metadata_to_json(@doc, ecli, @converter.metalex)
    @doc['_id'] = "#{ecli}:#{@doc['dcterms:modified']}"
    @doc['frbr:realizationOf'] = ecli
    unless rich_markup === nil
      @doc['hasRichMarkup'] = rich_markup
    end
    @doc['@type'] = 'frbr:Expression'

    # @converter.generate_html(@doc)
    # add_attachments
  end

  private
    # These attachments may or may not be available in the future, but currently not added due to space limitations.
    #
    # - metalex.xml can be generated through the web service
    # - inner.html and toc.html can be scraped from show.html
  def add_attachments
    @doc['_attachments'] ||= {}
    @doc['_attachments']['original.xml'] = {
        content_type: 'text/xml',
        data: Base64.encode64(@converter.original.to_s)
    }
    @doc['_attachments']['show.html'] = {
        content_type: 'text/html',
        data: Base64.encode64(@converter.html_show.to_s)
    }


    @doc['_attachments']['metalex.xml'] = {
        content_type: 'text/xml',
        data: Base64.encode64(@converter.metalex.to_s)
    }
    @doc['_attachments']['inner.html'] = {
        content_type: 'text/html',
        data: Base64.encode64(@converter.html_inner.to_s)
    }
    @doc['_attachments']['toc.html'] = {
        content_type: 'text/html',
        data: Base64.encode64(@converter.html_toc.to_s)
    }
  end

  def is_about_this(about, ecli)
    !about or
        about.strip.length <= 0 or
        about.strip == "http://deeplink.rechtspraak.nl/uitspraak?id=#{ecli}" or
        (about == ecli and ecli and ecli.strip.length>0)
  end

  def shorten_http_prefix(property)
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

# noinspection RubyStringKeysInHashInspection
  def add_metadata_to_json(doc, ecli, n_xml)
    n_xml.xpath('//metalex:meta',
                {'metalex' => 'http://www.metalex.eu/metalex/1.0'}).each do |meta|
      val = shorten_http_prefix(meta['content'])
      if is_about_this(meta['about'], ecli)
        property = shorten_http_prefix(meta['property'])
        if doc[property] and doc[property] != val
          if property == 'dcterms:modified'
            puts "WARNING: documents already had a last modified date: #{doc[property]} (as opposed to #{val})"
          else
            # Make sure it's an array, because we have multiple values for this property
            unless doc[property].respond_to?('push')
              doc[property]=[doc[property]]
            end
            doc[property].push(val)
          end
        else
          doc[property] = val
        end
      else
        if meta['about'].match(/META/) or meta['about'].match(/mcontainer/)
          # Also store the moment when metadata was last changed
          doc['metadataModified'] = val
        end
      end
    end
    doc['@context'] = XmlConverter::JSON_LD_URI
  end
end
