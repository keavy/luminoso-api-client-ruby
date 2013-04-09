
class Thing

    def initialize
    end
    
    def do(options={})
        puts options[:some]
        options.each { |k,v| s = "key:#{k}, #{v}"; puts s}
    end
    
end

foo = Thing.new
parms = {:some=>"bar", :other=>"zoo"}
#foo.do(:some=>"bar", :other=>"zoo")
foo.do(parms)

