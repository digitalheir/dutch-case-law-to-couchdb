require 'nokogiri'

XSLT_TO_HTML = Nokogiri::XSLT(File.read('xslt/rechtspraak_to_html.xslt'))
xml = Nokogiri::XML(File.open('example_rechtspraak_doc.xml'))
html = XSLT_TO_HTML.transform(xml).to_s
File.open('example.html', 'w+') do |f|
  f.puts html
end