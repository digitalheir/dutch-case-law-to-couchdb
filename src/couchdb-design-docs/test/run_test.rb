require 'erb'
require 'json'

input =  'test.js.erb'

js = ERB.new(File.read(input)).result(binding)

File.write(input.sub(/\.erb$/,''), js)

puts `mocha`