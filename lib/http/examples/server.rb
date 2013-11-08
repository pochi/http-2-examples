require "rack/request"
require "rack/response"

module Rack
  class HttpServer
    def call(env)
      request = Request.new env
      response = Response.new
      response.write "hello world"
      response.finish
    end
  end
end

require 'rack'
require 'rack/showexceptions'
Rack::Server.start(
  :app => Rack::ShowExceptions.new(Rack::Lint.new(Rack::HttpServer.new)), :Port => 9292
)
