require "openssl"
require "../src/tunnel/cipher"

cipher = Tunnel::Cipher.new "123456"

text = "abcdefgHIJKLMNopqrstUVWXYZ"
ciphertext = cipher.encrypt text.to_slice
plaintext = cipher.decrypt ciphertext

p ciphertext
p ciphertext.size
p plaintext
p plaintext.size

cipher.reset

text2 = "1234567890!@$%^&*()[]{}-="
ciphertext = cipher.encrypt text2.to_slice
plaintext = cipher.decrypt ciphertext

p ciphertext
p ciphertext.size
p plaintext
p plaintext.size
