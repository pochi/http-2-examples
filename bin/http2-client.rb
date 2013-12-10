$: << "core_extensions" << "../core_extensions"

require 'optparse'
require 'socket'
require 'openssl'
require 'http/2'
require 'uri'

require 'connection_extension'
require 'client_extension'
require 'stream_extension'


DRAFT = 'HTTP-draft-06/2.0'

class Logger
  def initialize(id)
    @id = id
  end

  def info(msg)
    puts "[Stream #{@id}]: #{msg}"
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: client.rb [options]"

  opts.on("-d", "--data [String]", "HTTP payload") do |v|
    options[:payload] = v
  end
end.parse!


uri = URI.parse(ARGV[0] || 'http://localhost:8080/')
tcp = TCPSocket.new(uri.host, uri.port)
sock = nil

if uri.scheme == 'https'
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

  ctx.npn_protocols = [DRAFT]
  ctx.npn_select_cb = lambda do |protocols|
    puts "NPN protocols supported by server: #{protocols}"
    DRAFT if protocols.include? DRAFT
  end

  sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
  sock.sync_close = true
  sock.hostname = uri.hostname
  sock.connect

  if sock.npn_protocol != DRAFT
    puts "Failed to negotiate #{DRAFT} via NPN"
    exit
  end
else
  sock = tcp
end

conn = HTTP2::Client.new
conn.on(:frame) do |bytes|
  sock.print bytes
  sock.flush
end

stream = conn.new_stream
log = Logger.new(stream.id)

conn.on(:promise) do |promise|
  promise.on(:headers) do |h|
    log.info "promise headers: #{h}"
  end

  promise.on(:data) do |d|
    log.info "promise data chunk: <<#{d.size}>>"
  end
end

stream.on(:close) do
  log.info "stream closed"
  sock.close
end

stream.on(:half_close) do
  log.info "closing client-end of the stream"
end

stream.on(:headers) do |h|
  log.info "response headers: #{h}"
end


stream.on(:data) do |d|
  log.info "response data chunk: <<#{d}>>"
end

head = {
  ":scheme" => uri.scheme,
  ":method" => (options[:payload].nil? ? "get" : "post"),
  ":host" => [uri.host, uri.port].join(':'),
  ":path" => uri.path,
  "accept" => "*/*"
}


Thor::Shell::Color.new.say_status("[Memo]", "Start HTTP2.0 Request", :on_red)

if head[":method"] == "get"
  stream.headers(head, end_stream: true)
else
  stream.headers(head, end_stream: false)
  stream.data(options[:payload])
end

while !sock.closed? && !sock.eof?
  data = sock.read_nonblock(1024)
  # puts "Received bytes: #{data.inspect}"

  begin
    conn << data
  rescue Exception => e
    puts "Exception: #{e}, #{e.message} - closing socket."
    sock.close
  end
end
