require_relative 'couch/cloudant_rechtspraak'
require_relative 'rechtspraak-nl/rechtspraak_utils'

class DbUpdaterTokens

  def initialize
    @logger = Logger.new('update_couchdb_tokens.log')
    @couch_tokens = CloudantRechtspraak.new('ecli_tokens')
    @couch_mirror = CloudantRechtspraak.new('ecli')
  end

  # Updates our database that clones Rechtspraak.nl's documents along with their tokens and tags as a JSON structure.
  def start()
    today = Date.today.strftime('%Y-%m-%d')
    doc_last_updated = @couch_tokens.get_doc('informal_schema', 'general')


    revs_tokenized = @couch_tokens.get_current_revs
    puts "#{revs_tokenized.length} tokenized docs"
    revs_mirror = @couch_mirror.get_current_revs

    new = {}
    revs_mirror.each do |ecli, rev|
      unless revs_tokenized[ecli] == rev
        new[ecli] = rev
      end
    end
    puts "#{new.length} new docs"

    new.keys.each_slice(150) do |slice|
      src_docs = @couch_mirror.get_all_docs('ecli', {keys: slice})
      src_docs.each do |doc|
        ecli = doc['_id']

        cache_path = "/media/maarten/BA46DFBC46DF7819/ecli-dump/xml/#{ecli.gsub(':', '.')}.xml"
        if File.exists? cache_path and doc['metadataModified'] < '2015-06-01'
          xml = Nokogiri::XML File.open(cache_path)
        else
          puts "downloading http://rechtspraak.cloudant.com/ecli/#{ecli}/data.xml"
          xml = Nokogiri::XML open("http://rechtspraak.cloudant.com/ecli/#{ecli}/data.xml")
        end

        new_doc = RechtspraakExpressionTokenized.new(doc, xml).doc
        @couch_tokens.add_and_maybe_flush(new_doc)
      end
      @couch_tokens.flush
    end

    # Update the document that tracks our last update date
    doc_last_updated['date_last_updated_tokens'] = today
    @couch_tokens.put('/informal_schema/general', doc_last_updated.to_json)
    @logger.close
  end

  private
  # Checks given ECLIs to our database; call block for those we wish do update
  def evaluate_eclis_to_update(source_docs, &block)
    rows = @couch_tokens.get_ecli_last_modified source_docs
    our_revs = {}
    rows.each do |row|
      our_revs[row['id']] = {
          :_rev => row['value']['_rev'],
          :modified => row['value']['modified']
      }
    end

    source_docs.each do |doc|
      unless our_revs[doc[:id]] and our_revs[doc[:id]][:modified].gsub(/\+[0-9]{2}:[0-9]{2}$/, '') == doc[:updated].gsub(/\+[0-9]{2}:[0-9]{2}$/, '')
        block.call(doc[:id], our_revs[doc[:id]], doc)
      end
    end
  end
end