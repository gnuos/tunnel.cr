require "logger"
require "openssl"
require "option_parser"
require "./tunnel/cipher"
require "./tunnel/endpoint"
require "./tunnel/server"
require "./tunnel/client"
require "./tunnel/version"

LOG = Logger.new(STDOUT, level: Logger::DEBUG)

program = Path.new(PROGRAM_NAME).basename
version = Tunnel::VERSION

is_client = false
is_server = false
listen = "0.0.0.0:7777"
forward = ""
secret = "Avengers"

OptionParser.parse! do |parser|
  parser.banner = <<-BANNER
#{program}/#{version} - a fast and secure tcp tunnel

usage:
BANNER

  parser.on("-c", "--client", "start as a tunnel client") { is_client = true }
  parser.on("-s", "--server", "start as a tunnel server") { is_server = true }
  parser.on("-l ADDR", "--listen=ADDR", "listen to local port for connecting by other endpoint.(default: '0.0.0.0:7777')") { |addr| listen = addr }
  parser.on("-f ADDR", "--forward=ADDR", "forward to one endpoint or one reachable tcp address.") { |addr| forward = addr }
  parser.on("-p PASSWORD", "--pass=PASSWORD", "one secret which is used for encrypt all data of these endpoint.(default: 'Avengers')") { |password| secret = password }
  parser.on("-v", "--version", "show version") { puts "#{program.capitalize} #{version}"; exit }
  parser.on("-h", "--help", "show this help") {
    puts parser
    puts
    puts
    puts "Example: #{program} -s -l 0.0.0.0:7777 -f 127.0.0.1:9000 -p 'password'"
    puts "         #{program} -c -l 0.0.0.0:1080 -f 127.0.0.1:7777 -p 'password'"

    exit
  }

  parser.invalid_option do |flag|
    STDERR.puts "#{PROGRAM_NAME}: invalid option -- #{flag[1..-1]}"
    STDERR.puts parser
    exit(1)
  end

  parser.missing_option do |flag|
    STDERR.puts "#{PROGRAM_NAME}: option requires an argument -- '#{flag[1..-1]}'"
    STDERR.puts parser
    exit(1)
  end

  if ARGV.empty?
    puts parser
    puts
    puts
    puts "Example: #{program} -s -l 0.0.0.0:7777 -f 127.0.0.1:9000 -p 'password'"
    puts "         #{program} -c -l 0.0.0.0:1080 -f 127.0.0.1:7777 -p 'password'"

    exit
  end
end

if is_client && is_server
  STDERR.puts "#{PROGRAM_NAME}: mutually exclusive arguments: --client --server"
  exit(1)
end

if !is_client && !is_server
  STDERR.puts "#{PROGRAM_NAME}: must set one of arguments: --client --server"
  exit(1)
end

if forward.empty?
  STDERR.puts "#{PROGRAM_NAME}: no value to set forward address via --forward"
  exit(1)
end

begin
  _addr = Socket::IPAddress.parse("tcp://#{listen}")
  TCPServer.new(_addr.address, _addr.port).close
rescue ex : Socket::Error
  STDERR.puts ex.message
  exit(1)
end

begin
  _addr = Socket::IPAddress.parse("tcp://#{forward}")
  TCPSocket.new(_addr.address, _addr.port).close
rescue ex : Socket::Error
  STDERR.puts ex.message
  exit(1)
end

if is_server
  server = Tunnel::Server.new(listen, forward, secret)
  puts "Listen on #{listen} ..."
  server.start
end

if is_client
  client = Tunnel::Client.new(listen, forward, secret)
  puts "Listen on #{listen} ..."
  client.start
end
