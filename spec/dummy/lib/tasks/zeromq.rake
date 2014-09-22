# Note: You must install 0mq libraries separately for this rake task to work and uncomment associated gem 
# declaration in Gemfile.

require 'yajl'
#require 'ffi-rzmq'  uncomment to use.
require 'faraday'
require 'socket'


task :run_socket => :environment do
  $stdout.sync = true

  ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
  if ip
    socket_address = "tcp://#{ip.ip_address}:5555"
  else
    raise('Cannot determine IP address.')
  end
  
  context = ZMQ::Context.new
  socket = context.socket ZMQ::REP
  socket.bind socket_address
  
  STDOUT.puts "BINDING: #{socket_address}"
  
  connection = Faraday.new do |builder|
    builder.adapter :rack, Rails.application
  end

  Rails.logger = Logger.new(STDOUT)

  loop do
    socket.recv_string meta = ''
    socket.recv_string body = ''
  
    method, path, query, headers = YAML.load(meta)

    STDOUT.puts 'REQUEST'
    STDOUT.puts "  METHOD: #{method.inspect}"
    STDOUT.puts "  PATH: #{path.inspect}"
    STDOUT.puts "  QUERY: #{query.inspect}"
    STDOUT.puts "  HEADERS: #{headers.inspect}"
    STDOUT.puts "  BODY: #{body.inspect}"

    response = connection.send(method.downcase.to_sym) do |req|
      req.url File.join(socket_address, path)
      (headers || {}).each { |k, v| req.headers[k] = v }
      req.params = query || {}
      req.body = body
    end
    
    response_body = response.body || ''
    
    socket.send_string YAML.dump([response.status, response.headers]), ZMQ::SNDMORE
    socket.send_string response_body
  end
end
