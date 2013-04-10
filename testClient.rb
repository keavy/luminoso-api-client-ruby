require 'rubygems'
require 'json'
require 'luminoso_api'

def  conceptualSearch(project, srch_text, srch_num)
# Basic wrapper for of Conceptual Search
    result = project.get('projects/Siddhartha/docs/search/', :text=>srch_text, :limit=>'200')

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

project = LuminosoClient.new
code = project.connect('e26y767s' , 'georgek@gmail.com', 'aarus466xttaw682')
if code then
# GET API examples:
#    result = project.get('projects/')
#    result = project.get('projects/Siddhartha/topics/')
#    result = project.get('projects/Siddhartha/topics/stats/')
#    result = project.get('projects/Siddhartha/docs/correlations/')
#    result = project.put('projects/Siddhartha/', :desc=>"A Book")
#    result = project.put('projects/Siddhartha/', :desc=>"Book")
#    puts result
#    result = project.put('projects/Siddhartha/terms/ignorelist/', :term=>"Boo")
#    result = project.get('projects/Siddhartha/terms/ignorelist/')
    result = project.post('projects/Siddhartha/docs/correlations/')
#    result = project.post('projects/NewProject/docs', :json=>'[{"title": "A Document!", "text": "This is the text of my document."}]')
#    result = conceptualSearch(project, 'river', 10)

    puts result

end





