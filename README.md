Ruby bindings for the Luminoso client API
===========================================

This package contains Ruby code for interacting with a Luminoso text
processing server through its REST API.

Installation
---------------
You can download this repository and install it the usual way:

    ruby setup.rb

If you are installing into the main Ruby environment on a Mac or Unix
system, you will probably need to prefix those commands with `sudo` and
enter your password, as in `sudo ruby setup.rb`.

Getting started
---------------
You interact with the API using a LuminosoClient object, which sends HTTP
requests to URLs starting with a given path, and keeps track of your
authentication information.

```ruby
>> require 'luminoso_api'
>> client = LuminosoClient.new
>> client.connect(:username=>'my_username', :password=>'my_password')
>> client.get('/projects/my_account_id/my_project_id/terms')
[lots of terms and vectors here]
```

When you don't specify a URL, the URL will be set to v4 of the Luminoso API
(https://api.luminoso.com/v4/).

HTTP methods
------------

The URLs you can communicate with are documented at https://api.luminoso.com/v4/
 (or https://api.lumino.so/v3/ for v3).
That documentation is the authoritative source for what you can do with the
API, and this Ruby code is just here to help you do it.

A LuminosoClient object has methods such as `.get`, `.post`, and `.put`,
which correspond to the corresponding HTTP methods that the API uses. For
example, `.get` is used for retrieving information without changing anything,
`.post` is generally used for creating new things or taking actions, and `.put`
is generally used for updating information.

Examples
--------

Get a list of the projects you have access to:

```ruby
require 'luminoso_api'
client = LuminosoClient.new
client.connect(:username=>'jane', :password=>MY_SECRET_PASSWORD)
project_info_list = client.get('/projects/jane_account')
```


An example of working with a project, including the `upload` method
that we provide to make it convenient to upload documents in the right format:

```ruby
require 'luminoso_api'
client = LuminosoClient.new
client.connect(:username=>'jane', :password=>MY_SECRET_PASSWORD)

# Create a new project by POSTing its name
project_id = projects.post('/projects/jane_account/', :name=>'testproject')['project_id']

# Upload some documents

docs = [{:title => 'First example', :text => 'This is an example document.'},
        {:title => 'Second example', :text => 'Examples are a great source of inspiration.'},
        {:title => 'Third example', :text => 'Great things come in threes.'}]
client.upload("/projects/jane_account/#{project_id}/docs", docs)
job_id = client.post("/projects/jane_account/#{project_id}/docs/calculate")
```

This starts an asynchronous job, returning us its ID number. We can use
`wait\_for` to block until it's ready:

```ruby
client.wait_for("/projects/jane_account/#{project_id}/jobs/id/#{job_id}")
```

When the project is ready:

```ruby
response = client.get("/projects/jane_account/#{project_id}/terms")
terms = response.map {|dict| [dict["text"], dict["score"]]}
```

Vectors
-------
The semantics of terms are represented by "vector" objects, which this API
will return as inscrutable base64-encoded strings like this:

    'WAB6AJG6kL_6D_6yAHE__R9kSAE8BlgKMo_80y8cCOCCSN-9oAQcABP_TMAFhAmMCUA'

If you want to look inside these vectors and compare them to each other, download our library called pack64 (https://github.com/LuminosoInsight/pack64).

Other Resources
---------------
        
Auth instructions: http://wiki.services.lumino.so/how-to-write-an-api-client.html
API documentation: https://api.luminoso.com/v4/ and https://api.lumino.so/v3/
