require 'rubygems'
require 'json'
require 'luminoso_api'

def  conceptualSearch(project, srch_text, srch_num)
# Basic wrapper for of Conceptual Search
    result = project.get('e26y767s/projects/Siddhartha/docs/search/', :text=>srch_text, :limit=>'200')

    h = JSON.parse(result)
    h['result']['matches'].each do |match|
        if not match[2].upcase.include? srch_text.upcase         # ignore exact matches
            print match[2]
            print "\n"
            srch_num-=1; if srch_num<1; break; end                  # governor
        end
    end
    return result
end

#_______________________________________________________________________________________________

client = LuminosoClient.new
login = project.connect('georgek@gmail.com', 'aarus466xttaw682')
if login['result']['key_id'] then
# GET API examples:
#    result = client.get('e26y767s/projects/')
#    result = client.get('e26y767s/projects/Siddhartha/topics/')
#    result = client.get('e26y767s/projects/Siddhartha/topics/stats/')
#    result = client.get('e26y767s/projects/Siddhartha/docs/correlations/')
#    result = client.put('e26y767s/projects/Siddhartha/', :desc=>"A Book")
#    result = client.put('e26y767s/projects/Siddhartha/', :desc=>"Book")
#    puts result
#    result = client.put('e26y767s/projects/Siddhartha/terms/ignorelist/', :term=>"Boo")
#    result = client.get('e26y767s/projects/Siddhartha/terms/ignorelist/')
#    result = client.post('e26y767s/projects/Siddhartha/docs/correlations/')
    result = client.upload('e26y767s/projects/NewProject/docs',
                           [{:title => "A Document!",
                             :text => "This is the text of my document."}])
#    result = conceptualSearch(project, 'river', 10)

    puts result

end





