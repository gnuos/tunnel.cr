module Tunnel
  class Server < EndPoint
    private def prepare_send(buf : Bytes) : Bytes
      cipher = Cipher.new options.secret
      block = cipher.decrypt buf
      cipher.reset
      block
    end

    private def prepare_recv(buf : Bytes) : Bytes
      cipher = Cipher.new options.secret
      block = cipher.encrypt buf
      cipher.reset
      block
    end
  end
end
