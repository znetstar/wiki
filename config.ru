require 'json'
require 'sinatra/base'
require 'sinatra/reloader'
require 'pg'

require_relative 'server'
use Rack::MethodOverride

Rack::Handler.default.run(Wiki::Server, :Port => (ENV['PORT'] || 7003))