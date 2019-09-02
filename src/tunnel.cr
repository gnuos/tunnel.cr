require "logger"
require "openssl"
require "option_parser"
require "./tunnel/cipher"
require "./tunnel/endpoint"
require "./tunnel/server"
require "./tunnel/client"
require "./tunnel/version"
require "./tunnel/options"

module Tunnel
  PROGRAM = Path.new(PROGRAM_NAME).basename

  class Cli
    def self.run
      options = Tunnel::Options.new
      listen = "0.0.0.0:7777"
      forward = ""
      is_client = false
      is_server = false

      OptionParser.parse! do |parser|
        parser.banner = <<-BANNER
#{PROGRAM}/#{VERSION} - a fast and secure tcp tunnel

usage:
    run as server : #{PROGRAM} -s -l 0.0.0.0:7777 -f 127.0.0.1:9000 -p 'password'
    run as client : #{PROGRAM} -c -l 0.0.0.0:1080 -f 127.0.0.1:7777 -p 'password'

BANNER

        parser.on("-c", "--client", "start as a tunnel client") { is_client = true }
        parser.on("-s", "--server", "start as a tunnel server") { is_server = true }
        parser.on("-d", "--debug", "(optional) enable print debug logs") { options.debug_log = true }
        parser.on("-l ADDR", "--listen=ADDR", "listen to local port for connecting by other endpoint, default: '0.0.0.0:7777'") { |addr| listen = addr }
        parser.on("-f ADDR", "--forward=ADDR", "forward to one endpoint or one reachable tcp address.") { |addr| forward = addr }
        parser.on("-p PASSWORD", "--pass=PASSWORD", "password to gen symetric key, default: 'Avengers'") { |password| options.secret = password }
        parser.on("-t", "--transparent", "(optional) enable transport data transparently.") { options.is_transparent = true }
        parser.on("-v", "--version", "show version") { puts "#{PROGRAM.capitalize} #{VERSION}"; exit }
        parser.on("-h", "--help", "print this help message") { puts parser; exit }

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
        options.listen = Socket::IPAddress.parse("tcp://#{listen}")
        TCPServer.new(options.listen.address, options.listen.port).close
      rescue ex : Socket::Error
        STDERR.puts ex.message
        exit(1)
      end

      begin
        options.forward = Socket::IPAddress.parse("tcp://#{forward}")
        TCPSocket.new(options.forward.address, options.forward.port).close
      rescue ex : Socket::Error
        STDERR.puts ex.message
        exit(1)
      end

      if is_server
        server = Tunnel::Server.new(options)
        puts "Listen on #{listen} ..."
        server.start
      end

      if is_client
        client = Tunnel::Client.new(options)
        puts "Listen on #{listen} ..."
        client.start
      end
    end
  end
end

Tunnel::Cli.run
