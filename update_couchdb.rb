require 'date'
require 'nokogiri'
require 'json'
require 'erb'
require 'logger'
require 'tilt'
require 'open-uri'
require 'base64'
require_relative 'db_updater_mirror'
require_relative 'db_updater_tokens'
require_relative 'rechtspraak-nl/rechtspraak_utils'
include RechtspraakUtils

# Script to keep Rechtspraak.nl data set clone up to date. Run daily. Enforced consistency on Saturday, meaning that the
# script checks for *all* documents, not only those that report to have been updated after we last successfully
# performed this script.
enforce_consistency = Date.today.saturday?
DbUpdaterMirror.new.start(enforce_consistency)
# DbUpdaterTokens.new.start()