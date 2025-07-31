#!/usr/bin/env ruby

require 'xmlrpc/server'
require 'xmlrpc/client'
require 'thread'
require 'timeout'

# Run server in a new thread, otherwise the script blocks
server_started = false
server_thread = Thread.new do
  server = XMLRPC::Server.new(8080, '127.0.0.1')

  server.add_handler("sample.add") do |a, b|
    a + b
  end

  # trap to shutdown server on interrupt
  trap("INT") { server.shutdown }

  server_started = true
  puts "XMLRPC server started on port 8080."
  server.serve
end

begin
  Timeout::timeout(5) do
    sleep 0.1 while !server_started
  end
  client = XMLRPC::Client.new("127.0.0.1", "/", 8080)
  result = client.call("sample.add", 2, 3)
  puts "2+3 - Client got result: #{result}\n"  # should print 5
rescue => e
  puts "Error during test: #{e.class}: #{e.message}"
  exit 1
ensure
  # Shutdown the server thread gracefully
  Thread.kill(server_thread)
  server_thread.join
end
