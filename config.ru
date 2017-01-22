require 'json'
require 'sinatra/base'
require 'sinatra/reloader'
require 'pg'

require_relative 'server'
Wiki::Server.run!