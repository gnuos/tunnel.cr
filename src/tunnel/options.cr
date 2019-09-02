struct Tunnel::Options
  getter? debug_log : Bool
  getter? is_transparent : Bool

  property listen : Socket::IPAddress
  property forward : Socket::IPAddress
  property secret : String

  def initialize(@listen, @forward, @secret, @debug_log = false, @is_transparent = false)
  end

  def self.new
    listen = Socket::IPAddress.parse("tcp://0.0.0.0:7777")
    forward = uninitialized Socket::IPAddress
    new(listen: listen, forward: forward, secret: "Avengers")
  end

  def self.new(forward : Socket::IPAddress, secret : String)
    new(forward: forward, secret: secret)
  end

  def debug_log=(value : Bool)
    @debug_log = value
  end

  def is_transparent=(value : Bool)
    @is_transparent = value
  end
end
