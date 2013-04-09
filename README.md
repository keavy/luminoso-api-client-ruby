# Luminoso Ruby Client implementation    
    
# example:        
project = LuminosoClient.new   
code = project.connect([account], [username], [password])   
if code then   
# GET API examples:   
    result = project.get('projects/')   
    puts result   
  
     
~/Ruby$ ruby testClient.rb     
{    
  "result": "OK",   
  "error": null   
}    
~/Ruby$     
   
   
API code is in: luminoso_api.rb   
 Sample calls: testClient.rb   
        
Auth instructions: http://www.luminoso.com/api-auth-v3.txt   
API documentation: https://api.lumino.so/v3/   


