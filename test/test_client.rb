require 'test/unit'
require 'rubygems'
require 'json'
require 'lib/luminoso_api'

class TestClient < Test::Unit::TestCase

    # make sure we can log in
    def setup
        # eww.
        output = `tellme lumi-test`.gsub(/u'([^:])/, "'\\1").gsub("'", '"')
        user_info = JSON.parse(output)
        username = user_info['username']
        @account = user_info['username']
        password = user_info['password']
        
        @client = LuminosoClient.new
        # this uses the real https://api.lumino.so/v3/
        response = @client.connect(username, password)
        assert(response['result']['key_id'], response['result'])
        @project = "ruby-api-client-test-#{ENV['USER']}-#{Process.pid}"
    end

    # get a non-json page
    def test_2_documentation
        documentation = @client.get_raw('/')
        assert(documentation.strip.start_with?(
               'This API supports the following methods.'),
               documentation.slice(0, 100))
    end

    # get a json response
    def test_3_get_projects
        response = @client.get("/#{@username}/projects")
        assert(response['error'] == nil, response)
        assert(response['result'][0].has_key?('name'), response)
    end

    # post request
    def test_4_create_project
        response = @client.post("/#{@account}/projects/", :project=>@project)
        assert(response['error'] == nil, response)
        assert(response['result']['name'] == @project, response)
    end

    # post data (upload documents)
    def test_5_upload
        my_docs = [{:title => 'doc', :text => 'here is a document'}]
        response = @client.upload("/#{@account}/projects/#{@project}/docs/",
                                  my_docs)
        assert(response['error'] == nil, response)
        job_id = response['result']
        assert(job_id.is_a?(Integer), response)
        puts "waiting for /#{@account}/projects/#{@project}/jobs/id/#{job_id}/"
        response = @client.wait_for(
            "/#{@account}/projects/#{@project}/jobs/id/#{job_id}/")
        assert(response['error'] == nil, response)
        assert(response['result'].has_key?('success'))
    end

    # delete request
    def test_6_delete_project
        response = @client.delete("/#{@account}/projects/", :project=>@project)
        assert(response['error'] == nil, response)
        assert(response['result'] == 'Deleted.', response)
    end

end
