require_relative '../rechtspraak-nl/rechtspraak_utils'
include RechtspraakUtils

doc= create_expression('ECLI:NL:GHSHE:2014:1641').doc
doc['_attachments']=nil

puts JSON.pretty_generate(doc)