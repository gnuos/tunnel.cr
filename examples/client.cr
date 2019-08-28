require "../src/tunnel"

listen = "0.0.0.0:8844"
backend = "127.0.0.1:1080"
password = "12345678"

client = Tunnel::Client.new(listen, backend, password)
puts "Listen on #{listen} ..."
client.start
