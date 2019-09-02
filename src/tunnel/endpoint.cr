module Tunnel
  abstract class EndPoint
    property options : Options

    def initialize(@options : Options)
      raise "please give your secret to secure the tunnel" if !options.is_transparent? && options.secret.empty?

      @sessions_count = 0_i32
    end

    def listen(host : String, port : Int32, reuse_port : Bool = false)
      server = TCPServer.new(host, port, reuse_port: reuse_port)
      loop do
        conn = server.accept?
        if conn
          spawn transport(conn)
        end
      end
    end

    def start
      listen options.listen.address, options.listen.port
    end

    private abstract def prepare_recv(buf : Bytes) : Bytes
    private abstract def prepare_send(buf : Bytes) : Bytes

    private def transport(client : TCPSocket)
      upstream = uninitialized TCPSocket

      begin
        start_time = Time.now
        upstream = TCPSocket.new(options.forward.address, options.forward.port)
        connect_time = (Time.now - start_time).total_nanoseconds

        read_bytes = 0_u64
        write_bytes = 0_u64
        start_time = Time.now # 在连接成功后开始计算传输时间
        client_terminated = Channel(Bool).new
        upstream_terminated = Channel(Bool).new

        @sessions_count += 1

        source_addr = client.remote_address
        target_addr = upstream.remote_address

        puts sprintf("[#{Time.now.to_unix_f}]\t-- :  [tcp] %s -- %s", source_addr, target_addr)

        spawn do
          buffer = uninitialized UInt8[4096]
          # 循环读取下游的请求，发送给上游
          loop do
            begin
              len = client.read(buffer.to_slice).to_i32
              unless len > 0
                if len == 0
                  puts "[#{Time.now.to_unix_f}]\t-- :  [tcp] #{source_addr} disconnected." if options.debug_log?

                  upstream.close_write
                  upstream.close_read
                elsif Errno.value != Errno::EAGAIN && Errno.value != Errno::EWOULDBLOCK
                  client.close_read unless client.peek.empty?
                end
                break
              end

              data = buffer.to_slice[0, len]
              data = prepare_recv(data) unless options.is_transparent?
              upstream.write(data)
              write_bytes += len

              puts sprintf("[#{Time.now.to_unix_f}]\t-- :    [tcp] %s --> %s ... #{len} bytes\t##{@sessions_count}", source_addr, target_addr) if options.debug_log?
            rescue Errno
              break if Errno.value == Errno::ENOTCONN
            rescue ex
              handle_exception(ex)
              break
            end
          end

          client_terminated.send true
        end

        spawn do
          buffer = uninitialized UInt8[4096]
          # 循环读取上游的响应，发送给下游
          loop do
            begin
              len = upstream.read(buffer.to_slice).to_i32
              unless len > 0
                if len == 0
                  puts "[#{Time.now.to_unix_f}]\t-- :  [tcp] #{target_addr} disconnected."

                  client.close_write
                  client.close_read
                elsif Errno.value != Errno::EAGAIN && Errno.value != Errno::EWOULDBLOCK
                  upstream.close_read if upstream.peek.empty?
                end
                break
              end

              data = buffer.to_slice[0, len]
              data = prepare_recv(data) unless options.is_transparent?
              client.write(data)
              read_bytes += len

              puts sprintf("[#{Time.now.to_unix_f}]\t-- :    [tcp] %s <-- %s ... #{len} bytes\t##{@sessions_count}", source_addr, target_addr) if options.debug_log?
            rescue Errno
              break if Errno.value == Errno::ENOTCONN
            rescue ex
              # handle_exception(ex)
              break
            end
          end

          upstream_terminated.send true
        end

        # 确认下游和上游都已经断开连接
        if client_terminated.receive && upstream_terminated.receive
          transfer_time = (Time.now - start_time).total_nanoseconds

          puts sprintf("[#{Time.now.to_unix_f}]\t-- :  [tcp] %s <-> %s ... #{transfer_time}ns\t##{@sessions_count}", source_addr, target_addr) if options.debug_log?
          puts sprintf("[Tun--#{source_addr}]\t-- :  read:%d(bytes) write:%d(bytes) c_time:%.1fns t_time:%.1fns session:#%d\n",
            read_bytes, write_bytes, connect_time, transfer_time, @sessions_count) if options.debug_log?
        end
      rescue e
        # handle_exception(e)
        return
      ensure
        upstream.close unless upstream.closed?
      end
    ensure
      client.close unless client.closed?
      @sessions_count -= 1
    end

    private def handle_exception(e : Exception)
      e.inspect_with_backtrace STDERR
      STDERR.flush
    end
  end
end
