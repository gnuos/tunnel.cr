module Tunnel
  enum Type
    Server
    Client
  end

  abstract class EndPoint
    property secret : String
    property cipher : Cipher
    property bind_addr : Socket::IPAddress
    property toward_addr : Socket::IPAddress

    def initialize(from : String, to : String, @secret : String)
      raise "please give your secret to secure the tunnel" if secret.empty?

      @bind_addr = Socket::IPAddress.parse("tcp://#{from}")
      @toward_addr = Socket::IPAddress.parse("tcp://#{to}")

      @sessions_count = 0_i32
      @cipher = uninitialized Cipher
    end

    def listen(host : String, port : Int32, reuse_port : Bool = false)
      begin
        server = TCPServer.new(host, port, reuse_port: reuse_port)

        loop do
          if conn = server.accept?
            spawn transport(conn)
          end
        end
      rescue e
        handle_exception(e)
      end
    end

    def start
      listen @bind_addr.address, @bind_addr.port
    end

    private abstract def read(buf : Bytes) : Bytes
    private abstract def write(buf : Bytes) : Bytes

    private def pipe(src : IO, dest : IO) : UInt64
      count = 0_u64

      begin
        buffer = uninitialized UInt8[4096]
        src.read_timeout = Time::Span.new(0, 0, 2)
        while (len = src.read(buffer.to_slice).to_i32) > 0
          dest.write_timeout = Time::Span.new(0, 0, 2)
          data = buffer.to_slice[0, len]
          dest.write yield data
          count += len
        end
      rescue IO::Timeout
        return count
      rescue e
        handle_exception(e)
      end
      count
    end

    private def pipe(src : IO, dest : IO, r_chan : Channel(UInt64), w_chan : Channel(UInt64))
      @cipher = Cipher.new(secret)
      spawn {
        count = pipe(src, dest) do |data|
          # 从本地监听的连接接收的数据发送给上游的连接，就是写数据到上游
          write data
        end
        w_chan.send count
      }

      spawn {
        count = pipe(dest, src) do |data|
          # 从上游的连接接收的数据发送给本地监听的连接，就是从上游读数据
          read data
        end
        r_chan.send count
      }
    end

    private def transport(client : TCPSocket)
      begin
        start_time = Time.now
        TCPSocket.open(@toward_addr.address, @toward_addr.port) do |sock|
          connect_time = Time.now - start_time

          @sessions_count += 1
          read_bytes = 0_u64
          write_bytes = 0_u64
          read_chan = Channel(UInt64).new
          write_chan = Channel(UInt64).new

          start_time = Time.now

          pipe(client, sock, read_chan, write_chan)

          read_bytes = read_chan.receive
          write_bytes = write_chan.receive
          transfer_time = Time.now - start_time

          printf "r:%d w:%d ct:%.3f t:%.3f [#%d]\n", read_bytes, write_bytes, connect_time.to_f, transfer_time.to_f, @sessions_count
        end
      rescue e
        handle_exception(e)
      end
    rescue IO::EOFError
      puts "#{client.remote_address} disconnected"
    ensure
      client.close
      @sessions_count -= 1
    end

    private def handle_exception(e : Exception)
      e.inspect_with_backtrace STDERR
      STDERR.flush
    end
  end
end
