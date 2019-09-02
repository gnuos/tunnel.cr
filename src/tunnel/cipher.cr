module Tunnel
  struct Cipher
    property encryptor : OpenSSL::Cipher
    property decryptor : OpenSSL::Cipher

    @key : Bytes
    @iv : Bytes

    def initialize(secret : String)
      raise "secret must be provided" if secret.nil?
      raise "secret size must be greater than 6" if secret.size < 6

      @encryptor = OpenSSL::Cipher.new("AES-256-GCM")
      @decryptor = OpenSSL::Cipher.new("AES-256-GCM")

      h = OpenSSL::Digest.new("SHA256")
      @key = h.update(secret.to_slice).digest
      h.reset

      h = OpenSSL::Digest.new("SHA256")
      @iv = h.update(secret.to_slice.clone.reverse!).digest
      h.reset

      init
    end

    def encrypt(data : Bytes) : Bytes
      chunk = @encryptor.update(data)
      remain = @encryptor.final

      encrypted = String.new(chunk) + String.new(remain)
      encrypted.to_slice
    end

    def decrypt(data : Bytes) : Bytes
      chunk = @decryptor.update(data)
      remain = @decryptor.final

      decrypted = String.new(chunk) + String.new(remain)
      decrypted.to_slice
    end

    def reset
      @encryptor.reset
      @decryptor.reset
    end

    def init
      @encryptor.encrypt
      @decryptor.encrypt

      @encryptor.key = @key
      @decryptor.key = @key

      @encryptor.iv = @iv
      @decryptor.iv = @iv
    end
  end
end
