require 'base64'
require 'openssl'

signature =
"GET
api.lumino.so
/v3/lui/projects/


1342758911406
key_id: IZj79BvIiW0uZw-IYJXgDd53Mua4RUdg
"

signature2 =
"POST
api.lumino.so
/v3/dashboard/pipeline_test/topics/create/


1343316416573
color: #e2105f
key_id: c_vwaEaUuvn6kmK4pigas93nvFxRKJIh
name: New%20Topic
terms: %5B%5D
"

secret = 'jAX_FJfN4CiLGhJrkxg40DA0Fum9vVbG'
secret2 ='R8BA2gjkBl4yExNgIYawzRtu5NzmsBoy'

digested = OpenSSL::HMAC.digest('sha1', secret2, signature2)
encoded = Base64.encode64(digested).chomp

puts encoded
puts "Success:" + (encoded == "k8NNivwHQrAckdTl3LNRhW3hkF0=").to_s

