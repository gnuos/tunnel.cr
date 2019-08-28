require "openssl"
require "../src/cipher"

cipher = Tunnel::Cipher.new "123456"

text = "abcdefgHIJKLMNopqrstUVWXYZ"
ciphertext = cipher.encrypt text.to_slice
plaintext = cipher.decrypt ciphertext

p ciphertext
p ciphertext.size
p plaintext
p plaintext.size
