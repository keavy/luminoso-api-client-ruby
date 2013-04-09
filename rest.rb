require 'rubygems'
require 'rest_client'

url = 'https://api.lumino.so/v3/'
auth_url = 'https://api.lumino.so/v3/.auth/login/'
resource = RestClient::Request.new(:url => auth_url, :method => 'post', :user => 'georgek@gmail.com',  :password => 'aarus466xttaw682')

puts resource.class
puts resource.processed_headers


