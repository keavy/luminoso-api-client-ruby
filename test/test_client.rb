require 'test/unit'
require 'rubygems'
require 'json'
require 'lib/luminoso_api'

class TestClient < Test::Unit::TestCase

    # make sure we can log in
    def setup
        output = `tellme lumi-test -f json`
        user_info = JSON.parse(output)
        username = user_info['username']
        @account = user_info['username']
        password = user_info['password']

        @client = LuminosoClient.new
        response = @client.connect(username, password)
        assert(response['key_id'], response)
        @token_client = LuminosoClient.new
        response = @token_client.connect(username, password, true)
        assert(response['token'], response)

        @project = "ruby-api-client-test-#{ENV['USER']}-#{Process.pid}"
    end

    # get a non-json page
    def test_2_documentation
        for client in [@client, @token_client] do
            documentation = client.get_raw('/')
            assert(documentation.strip.start_with?(
                       'This API supports the following methods.'),
                       documentation.slice(0, 100))
        end
    end

    # get a json response
    def test_3_get_projects
        for client in [@client, @token_client] do
            response = client.get("/projects/#{@account}")
            assert(response[0].has_key?('name'), response)
        end
    end

    # post request
    def test_4_create_project
        response = @client.post("/projects/#{@account}/", :name=>@project)
        assert(response['name'] == @project, response)
    end

    # post data (upload documents)
    def test_5_upload
        my_docs = [{:title => 'doc', :text => 'here is a document'}]
        # get the project_id again, because apparently setting @project_id in
        # the test_4_create_project method doesn't actually work.
        project_id = @client.get("/projects/#{@account}/",
                                 :name=>@project)[0]["project_id"]
        for client in [@client, @token_client] do
            ids = client.upload("/projects/#{@account}/#{project_id}/docs/",
                                 my_docs)
            assert(ids.length == my_docs.length, ids)
            job_id = client.post(
                         "/projects/#{@account}/#{project_id}/docs/recalculate")
            assert(job_id.is_a?(Integer), job_id)
            puts "waiting for /projects/#{@account}/#{project_id}/jobs/id/#{job_id}/"
            response = client.wait_for(
                           "/projects/#{@account}/#{project_id}/jobs/id/#{job_id}/")
            assert(response.has_key?('success'))
        end
    end

    # delete request
    def test_6_delete_project
        project_id = @client.get("/projects/#{@account}/",
                                 :name=>@project)[0]["project_id"]
        response = @client.delete("/projects/#{@account}/#{project_id}/")
        assert(response == 'Deleted.', response)
    end

end
