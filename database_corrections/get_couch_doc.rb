require_relative '../rechtspraak-nl/rechtspraak_utils'
include RechtspraakUtils

doc= create_couch_doc('ECLI:NL:GHSHE:2014:1641')
doc['_attachments']=nil

puts JSON.pretty_generate(doc)