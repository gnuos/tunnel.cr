module Tunnel
  class Cipher
    @key : Slice(UInt8)
    @iv : Slice(UInt8)

    def initialize(secret : String)
      h = OpenSSL::Digest.new("SHA256")
      @key = h.update(secret.to_slice).digest
      h.reset

      h = OpenSSL::Digest.new("SHA256")
      @iv = h.update(secret.to_slice.clone.reverse!).digest
      h.reset

      @encryptor = OpenSSL::Cipher.new("AES-256-GCM")
      @decryptor = OpenSSL::Cipher.new("AES-256-GCM")

      cipherinit
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

      cipherinit
    end

    private def cipherinit
      @encryptor.encrypt
      @decryptor.encrypt

      @encryptor.key = @key
      @decryptor.key = @key

      @encryptor.iv = @iv
      @decryptor.iv = @iv
    end
  end
end
