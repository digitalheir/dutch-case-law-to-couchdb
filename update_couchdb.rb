require 'nokogiri'
require 'json'
require 'erb'
require 'logger'
require 'tilt'
require 'open-uri'
require 'base64'
require_relative 'couch/couch'
require_relative 'rechtspraak-nl/rechtspraak_utils'
include RechtspraakUtils

update_couchdb
