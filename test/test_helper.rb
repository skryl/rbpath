require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'
require 'yaml'
require 'set'
require 'minitest/autorun'
require 'minitest/pride'

# extend minitest to support out of order array matches
#
require_relative 'extensions/match_array'
