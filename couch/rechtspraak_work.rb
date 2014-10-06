class RechtspraakWork
  attr_reader :doc

  # Initializes this work. Note that we expect from_expression to be the latest expression, and so copy any relevant metadata from there.
  def initialize(ecli, from_expession)
    @doc = from_expession.clone
    if @doc['_rev']
      @doc.delete '_rev'
    end
    @doc.delete 'frbr:realizationOf'
    @doc.delete '_attachments'

    @doc['@type'] = 'frbr:LegalWork'
    @doc['_id'] = ecli
    @doc["@context"] = JSON_LD_URI
    @doc["dcterms:source"] = "http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"

    # add_expression_and_set_latest(from_expession['_id'])
  end

  def add_expression_and_set_latest(expression_id)
    add_expression(expression_id)
    @doc['latestExpression'] = expression_id
  end

  def add_expression(expression_id)
    @doc['frbr:realization'] ||= []
    @doc['frbr:realization'] << expression_id
  end

  def set_show_html(show_hmtl)
    @doc['_attachments'] ||= {}
    @doc['_attachments']['show.html'] = show_hmtl
  end
end
