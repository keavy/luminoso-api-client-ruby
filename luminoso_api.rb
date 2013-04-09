# Luminoso Ruby API client
require 'rubygems'
require 'rest_client'
require 'json'
require 'base64'
require 'openssl'
require 'open-uri'

class LuminosoClient
    @@base_url = 'https://api.lumino.so/v3/'
    @@login_url = 'https://api.lumino.so/v3/.auth/login/'

    def initialize
        @project = nil
        @session_cookie = nil
        @key_id = nil
        @secret = nil
        @expires = nil
        @session_cookie = nil
    end


#__________________________________________________
# AUTH
    def connect(project, user, password)
        account_url = @@base_url + project + '/'
        # AUTH credentials
        begin
            response = RestClient.post(@@login_url,
                           {:username => user,
                            :password => password,
                            :content_type => 'application/x-www-form-urlencoded'
                           })
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @project = project
            @session_cookie = session_cookie[0]

            # get dictionary from response body
            h = JSON.parse(response.body)
            @key_id = h["result"]["key_id"].to_s
            @secret = h["result"]["secret"].to_s
            @expires = h["result"]["key_expires"].to_s    
            return @key_id
        rescue => e
            return nil
        end
    end

#__________________________________________________
#   GET 
# interface example: client.get('projects/foo/docs/search', :text=>'thing', :limit=>10)

    def get(api, options={})

        options.merge!(:key_id => @key_id)          # add key_id to options hash...
        sign_string =
"GET
api.lumino.so
/v3/"+@project + "/" + api + "


"+@expires+"\n"

        options.each {|k,v| options[k] = CGI.escape(v)}                   # URL encode each option
        sorted_options = options.sort_by {|sym| sym.to_s}      # alphabetical key (symbol) order 

        sorted_options.each do |option|                                   # iterate options alphabetically by symbol
            s = "#{option[0]}: #{option[1]}\n"; sign_string+=s
        end
#        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        encoded = Base64.encode64(digested).chomp           # encrypt the digest

        begin
            account_url = @@base_url + @project + '/'
            options.merge!(:sig => encoded, :expires => @expires)       # add sig, expires to params
            response = RestClient.get(account_url+api,
                             {:params => options, :cookie => @session_cookie})

            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @session_cookie = session_cookie[0]                     # update the cookie
        rescue => e
            response = e.message
        end
        return response
    end    


#__________________________________________________
#   PUT 
# interface example: client.put('projects/foo/', :desc=>'Project description')

    def put(api, options={})

        options.merge!(:key_id => @key_id)          # add key_id to options hash...
        sign_string =
"PUT
api.lumino.so
/v3/"+@project + "/" + api + "


"+@expires+"\n"

        sorted_options = options.sort_by {|sym| sym.to_s}                # alphabetical key (symbol) order 

        sorted_options.each do |option|                                             # iterate options alphabetically by symbol
            s = "#{option[0]}: #{URI::encode(option[1])}\n"; sign_string+=s
        end
#        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        encoded = Base64.encode64(digested).chomp                     # encrypt the digest

        begin
            account_url = @@base_url + @project + '/'
            options.merge!(:sig => encoded, :expires => @expires)       # add sig, expires to params
            response = RestClient.put(account_url+api, options, {:cookie => @session_cookie})
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @session_cookie = session_cookie[0]                                # update the cookie
        rescue => e
            response = e.message
        end
        return response
    end    

#__________________________________________________
#   POST
# interface example: client.put('projects/foo/', :desc=>'Project description')

    def post(api, options={})

        options.merge!(:key_id => @key_id)          # add key_id to options hash...
        sign_string =
"POST
api.lumino.so
/v3/"+@project + "/" + api + "


"+@expires+"\n"

        sorted_options = options.sort_by {|sym| sym.to_s}      # alphabetical key (symbol) order 

        sorted_options.each do |option|                                   # iterate options alphabetically by symbol
            s = "#{option[0]}: #{URI::encode(option[1])}\n"; sign_string+=s
        end
#        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        encoded = Base64.encode64(digested).chomp           # encrypt the digest

        begin
            account_url = @@base_url + @project + '/'
            options.merge!(:sig => encoded, :expires => @expires)       # add sig, expires to params
            response = RestClient.post(account_url+api, options, {:cookie => @session_cookie})

            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @session_cookie = session_cookie[0]                     # update the cookie
        rescue => e
            response = e.message
        end
        return response
    end    


end

