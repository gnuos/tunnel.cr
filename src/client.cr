module Tunnel
  class Client < EndPoint
    def initialize(from : String, to : String, secret : String)
      super(from, to, secret)
      @type = Type::Client
    end

    private def read(buf : Bytes) : Bytes
      @cipher.decrypt buf
    end

    private def write(buf : Bytes) : Bytes
      @cipher.encrypt buf
    end
  end
end
