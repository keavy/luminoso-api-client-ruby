require 'rubygems'
require 'rest_client'
require 'json'
require 'base64'
require 'openssl'

base_url = 'https://api.lumino.so/v3/'
login_url = base_url + '.auth/login/'
account = 'e26y767s'
account_url = base_url + account + '/'

# AUTH credentials
response = RestClient.post(login_url,
                           {:username => 'georgek@gmail.com',
                            :password => 'aarus466xttaw682',
                            :content_type => 'application/x-www-form-urlencoded'
                           })
session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
session_cookie = session_cookie[0]

puts session_cookie

# get dictionary from response body
h = JSON.parse(response.body)
key_id = h["result"]["key_id"].to_s
secret = h["result"]["secret"].to_s
expires = h["result"]["key_expires"].to_s

# Basic request
sign_string =
"GET
api.lumino.so
/v3/"+account+"/projects/


"+expires+"
key_id: "+key_id+"\n"

puts "==="
puts sign_string
puts "==="

digested = OpenSSL::HMAC.digest('sha1', secret, sign_string)
encoded = Base64.encode64(digested).chomp

begin
  response2 = RestClient.get(account_url+'projects/',
                             {:params => {:key_id => key_id,
                                          :sig => encoded,
                                          :expires => expires},
                              :cookie => session_cookie})
rescue => e
  response2 = e.response
end

#puts response2
puts response2.code
session_cookie = response2.headers[:set_cookie].select {|a| a.match(/^session/)}
session_cookie = session_cookie[0]
puts session_cookie




