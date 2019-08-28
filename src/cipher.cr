module Tunnel
  class Cipher
    def initialize(secret : String)
      h = OpenSSL::Digest.new("SHA256")
      key = h.update(secret.to_slice).digest
      iv = key.clone.reverse!

      @encryptor = OpenSSL::Cipher.new("AES-256-GCM")
      @decryptor = OpenSSL::Cipher.new("AES-256-GCM")

      @encryptor.encrypt
      @decryptor.encrypt

      @encryptor.key = key
      @decryptor.key = key

      @encryptor.iv = iv
      @decryptor.iv = iv
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
  end
end
