# Luminoso Ruby API client
require 'rubygems'
require 'rest_client'
require 'json'
require 'base64'
require 'digest/sha1'


# TODO:
# - raise exceptions on errors?
# - keepalive / auto-relogin?


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
            return h
        rescue RestClient::Exception => e
            return JSON.parse(e.http_body)
        end
    end


    # Make a request to the API.
    # req_type: 'GET', 'PUT', 'POST', 'DELETE', or 'PATCH'
    # path: path of the resource, relative to @url
    # url_params: url parameters (as a dictionary)
    # form_params: POST/PUT parameters (as a dictionary)
    # data: what to put into the body of the request (string)
    def request(req_type, path, url_params={}, form_params={}, data=nil,
                options={})

        # convert parameters to correct format
        url_params = jsonify_parameters(url_params)
        form_params = jsonify_parameters(form_params)

        # if uploading data, compute sha1 hash
        json_hash = ""
        content_type = ""
        request_body = form_params
        if data
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

        # iterate parameters alphabetically by symbol
        sorted_params.each do |option|
            s = "#{option[0]}: #{CGI.escape(option[1])}\n"
            sign_string += s
        end

        digested = OpenSSL::HMAC.digest('sha1', @secret, sign_string)
        # encrypt the digest
        encoded = Base64.encode64(digested).chomp

        begin
            if path == ''
                request_url = @url
            else
                request_url = @url + path + '/'
            end
            # add sig, expires to params
            url_params.merge!(:sig => encoded, :expires => @expires)

            # make the request
            method = RestClient.method(req_type.downcase)
            headers = {:cookie => @session_cookie,
                       :params => url_params}
            if content_type != ''
                headers[:content_type] = content_type
            end

            if ['PUT', 'POST', 'PATCH'].include?(req_type)
                # these have a request body
                response = method.call(request_url, request_body, headers)
            else
                response = method.call(request_url, headers)
            end

            # update the cookie
            if response.headers[:set_cookie]
                session_cookie = response.headers[:set_cookie].select {|a| a.match(/^session/)}
                @session_cookie = session_cookie[0]
            end
        rescue RestClient::Exception => e
            response = e.http_body
        end

        if options[:raw]
            return response
        else
            return JSON.parse(response)
        end
    end


    def get(path, params={})
        self.request('GET', path, params)
    end


    def put(path, params={})
        self.request('PUT', path, {}, params)
    end


    def post(path, params={})
        self.request('POST', path, {}, params)
    end


    def patch(path, params={})
        self.request('PATCH', path, {}, params)
    end


    def delete(path, params={})
        self.request('DELETE', path, params)
    end


    # Get the raw response body (as opposed to json-decoded).
    # This is used for the documentation endpoint (/) (plaintext),
    # as well as some endpoints that return CSV-formatted responses.
    def get_raw(path, params={})
        self.request('GET', path, params, {}, nil, {:raw=>true})
    end


    # Upload documents.
    # docs should be an array of hashes, each of which is one document
    def upload(path, docs, params={})
        self.request('POST', path, params, {}, JSON.generate(docs))
    end

    
    # Wait for a job to finish.
    # path should be something like '/myaccount/projects/myproject/jobs/id/22',
    #    where 22 is the job number returned by the upload/calculate request
    def wait_for(path)
        job_status = {}
        while true
            job_status = self.request('GET', path)
            if job_status['error'] || job_status['result']['stop_time']
                break
            end
        end
        return job_status
    end

end



# Convert parameters hash to correct format
# (strings stay the same, integers become strings,
#  hashes and arrays get json-encoded)
def jsonify_parameters(params)
    encoded_params = {}
    params.each_pair do |key, val|
        if val.is_a?(String)
            encoded_params[key] = val
        elsif val.is_a?(Integer)
            encoded_params[key] = val.to_s
        else
            encoded_params[key] = JSON.generate(val)
        end
    end
    return encoded_params
end


# Copied from someone on StackOverflow
# (http://stackoverflow.com/questions/3165891/ruby-string-strip-defined-characters)
def strip(string, chars)
  chars = Regexp.escape(chars)
  string.gsub(/\A[#{chars}]+|[#{chars}]+\Z/, '')
end
