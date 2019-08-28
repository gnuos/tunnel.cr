require "../src/tunnel"

BIND     = "0.0.0.0:1080"
BACKEND  = "31.40.214.85:80"
PASSWORD = "12345678"

server = Tunnel::Server.new(BIND, BACKEND, PASSWORD)
puts "Listen on #{BIND} ..."
server.start
