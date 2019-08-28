module Tunnel
  class Server < EndPoint
    def initialize(from : String, to : String, secret : String)
      super(from, to, secret)
      @type = Type::Server
    end

    private def read(buf : Bytes) : Bytes
      @cipher.encrypt buf
    end

    private def write(buf : Bytes) : Bytes
      @cipher.decrypt buf
    end
  end
end
