module Tunnel
  class Client < EndPoint
    private def prepare_send(cipher : Cipher, buf : Bytes) : Bytes
      cipher.encrypt buf
    end

    private def prepare_recv(cipher : Cipher, buf : Bytes) : Bytes
      cipher.decrypt buf
    end
  end
end
