# Luminoso Ruby API client
require 'rubygems'
require 'rest_client'
require 'json'
require 'base64'
require 'digest/sha1'


# TODO:
# - convert number/boolean arguments to strings
# - json-decode responses
# - figure out why it's giving "401 Unauthorized" instead of actual response


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
        @url = protocol + '://' + api_name + '/' + version + '/'
        if version == 'v3'
            login_url = @url + '.auth/login/'
        else
            login_url = @url + 'user/login/'
        end

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
            content_type = 'application/json'
            request_body = data
        end

        # strip '/' from path
        path = strip(path, '/')

        # add key_id to url parameters
        url_params.merge!(:key_id => @key_id)
        
        # parameters for sign string are url parameters and form parameters
        sign_params = url_params.merge(form_params)

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
            sign_string += s
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
            headers = {:cookie => @session_cookie,
                       :params => url_params}
            if content_type != '' then
                headers[:content_type] = content_type
            end

            if ['PUT', 'POST', 'PATCH'].include?(req_type) then
                # these have a request body
                response = method.call(request_body, headers)
            else
                response = method.call(headers)
            end

            # update the cookie
            session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
            @session_cookie = session_cookie[0]
        rescue => e
            response = e.message
        end
        return response
    end


    def get(path, options={})
        self.request('GET', path, options)
    end


    def put(path, options={})
        self.request('PUT', path, {}, options)
    end


    def post(path, options={})
        self.request('POST', path, {}, options)
    end


    def post_data(path, data, options={})
        self.request('POST', path, options, {}, data)
    end


    def patch(path, options={})
        self.request('PATCH', path, {}, options)
    end


    def delete(path, options={})
        self.request('DELETE', path, options)
    end

end



# Copied from someone on StackOverflow
# (http://stackoverflow.com/questions/3165891/ruby-string-strip-defined-characters)
def strip(string, chars)
  chars = Regexp.escape(chars)
  string.gsub(/\A[#{chars}]+|[#{chars}]+\Z/, '')
end
