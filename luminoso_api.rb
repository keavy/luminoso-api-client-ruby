# Luminoso Ruby API client
require 'rubygems'
require 'rest_client'
require 'json'
require 'base64'
require 'digest/sha1'


class LuminosoClient

    def initialize
        @username = nil
        @password = nil
        @api_name = nil
        @version = nil
        @protocol = nil
        @url = nil
        @session_cookie = nil
        @key_id = nil
        @secret = nil
        @expires = nil
        @session_cookie = nil
    end

    # Log in to Luminoso
    def connect(username=nil, password=nil, api_name='api.lumino.so',
                version='v3', protocol='https')
        @username = username
        @password = password
        @api_name = api_name
        @version = version
        @protocol = protocol
        @url = protocol + '/' + api_name + '/' + version + '/'
        login_url = @url + '.auth/login/'
        begin
            response = RestClient.post(login_url,
                                       {:username => username,
                                        :password => password
                                       })
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
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


    # Make a request to the API.
    # req_type: 'GET', 'PUT', 'POST', 'DELETE', or 'PATCH'
    # path: path of the resource, relative to @url
    # url_params: url parameters (as a dictionary)
    # form_params: POST/PUT parameters (as a dictionary)
    # data: what to put into the body of the request (string)
    def request(req_type, path, url_params={}, form_params={}, data=nil)

        # if uploading data, compute sha1 hash
        json_hash = ""
        content_type = ""
        request_body = form_params
        if data then
            sha1 = Digest::SHA1.digest(data)
            json_hash = Base64.encode64(sha1)
            # TODO: does content_type go in url params??
            content_type = url_params['content_type']
            request_body = data
        end

        # strip '/' from path
        path = strip(path, '/')

        # add key_id to url parameters
        params.merge!(:key_id => @key_id)
        
        # parameters for sign string are url parameters and form parameters
        sign_params = params.merge(form_params)

        sign_string = req_type + "\n"
        sign_string += @api_name + "\n"
        sign_string += "/#{@version}/#{path}/\n"
        sign_string += json_hash.chomp + "\n"
        sign_string += content_type + "\n"
        sign_string += @expires + "\n"

        # alphabetical key (symbol) order
        sorted_params = sign_params.sort_by {|sym| sym.to_s}

        # iterate options alphabetically by symbol
        sorted_params.each do |option|
            s = "#{option[0]}: #{CGI.escape(option[1])}\n"
            sign_string+=s
        end

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        # encrypt the digest
        encoded = Base64.encode64(digested).chomp

        begin
            request_url = @url + path + '/'
            # add sig, expires to params
            url_params.merge!(:sig => encoded, :expires => @expires)

            # make the request
            path_client = RestClient::Resource.new(request_url)
            method = path_client.method(req_type.downcase)
            method.call(request_body,
                        {:params => url_params,
                         :cookie => @session_cookie,
                         :content_type => content_type})

            # update the cookie
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @session_cookie = session_cookie[0]
        rescue => e
            response = e.message
        end
        return response
    end



#__________________________________________________
#   GET 
# interface example: client.get('projects/foo/docs/search', :text=>'thing', :limit=>10)

    def get(path, options={})

        # add key_id to options hash
        options.merge!(:key_id => @key_id)
        #"GET\n#{@api_name}\n"   ## ..........
        sign_string =
"GET
api.lumino.so
/v3/"+@project + "/" + path + "


"+@expires+"\n"

        # alphabetical key (symbol) order
        sorted_options = options.sort_by {|sym| sym.to_s}

        # iterate options alphabetically by symbol
        sorted_options.each do |option|
            s = "#{option[0]}: #{CGI.escape(option[1])}\n"
            sign_string+=s
        end
#        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        # encrypt the digest
        encoded = Base64.encode64(digested).chomp

        begin
            account_url = @@base_url + @project + '/'
            # add sig, expires to params
            options.merge!(:sig => encoded, :expires => @expires)
            response = RestClient.get(account_url+path,
                             {:params => options, :cookie => @session_cookie})

            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            # update the cookie
            @session_cookie = session_cookie[0]
        rescue => e
            response = e.message
        end
        return response
    end    


#__________________________________________________
#   PUT 
# interface example: client.put('projects/foo/', :desc=>'Project description')

    def put(path, options={})

        # add key_id to options hash
        options.merge!(:key_id => @key_id)
        sign_string =
"PUT
api.lumino.so
/v3/"+@project + "/" + path + "


"+@expires+"\n"

        # alphabetical key (symbol) order
        sorted_options = options.sort_by {|sym| sym.to_s}

        # iterate options alphabetically by symbol
        sorted_options.each do |option|
            s = "#{option[0]}: #{URI::encode(option[1])}\n"; sign_string+=s
        end
#        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        # encrypt the digest
        encoded = Base64.encode64(digested).chomp

        begin
            account_url = @@base_url + @project + '/'
            # add sig, expires to params
            options.merge!(:sig => encoded, :expires => @expires)
            response = RestClient.put(account_url+path, options, {:cookie => @session_cookie})
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            # update the cookie
            @session_cookie = session_cookie[0]
        rescue => e
            response = e.message
        end
        return response
    end

#__________________________________________________
#   POST
# interface example: client.put('projects/foo/', :desc=>'Project description')

    def post(path, options={})

        json = nil
        json_hash = ""
        content_type = ""
        # process JSON
        if options[:json] then
            json = options[:json]
            # Hash the JSON
            sha1 = Digest::SHA1.digest(json)
            json_hash = Base64.encode64(sha1)        
            content_type = "application/json"
            options.delete(:json)
        end
        
        # add key_id to options hash
        options.merge!(:key_id => @key_id)

        sign_string =
"POST
api.lumino.so
/v3/"+@project + "/" + api + "
" + json_hash.chomp + "
" + content_type + "
"+@expires+"\n"

        # alphabetical key (symbol) order
        sorted_options = options.sort_by {|sym| sym.to_s}

        # iterate options alphabetically by symbol
        sorted_options.each do |option|
            s = "#{option[0]}: #{URI::encode(option[1])}\n"; sign_string+=s
        end
        puts "===\n"+sign_string+"==="

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        # encrypt the digest
        encoded = Base64.encode64(digested).chomp

        begin
            account_url = @@base_url + @project + '/'
            # add sig, expires to params
            options.merge!(:sig => encoded, :expires => @expires)
            response = RestClient.post(account_url+path,
                                       options,
                                       {:cookie => @session_cookie})

            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            # update the cookie
            @session_cookie = session_cookie[0]
        rescue => e
            response = e.message
        end
        return response
    end    


end



# Copied from someone on StackOverflow
# (http://stackoverflow.com/questions/3165891/ruby-string-strip-defined-characters)
def strip(string, chars)
  chars = Regexp.escape(chars)
  string.gsub(/\A[#{chars}]+|[#{chars}]+\Z/, '')
end
