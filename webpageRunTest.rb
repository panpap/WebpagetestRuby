#!/usr/bin/env ruby
require "net/http"
require "uri"
require "json"
require "csv"

@queryNode="http://www.webpagetest.org/"
@runTest="runtest.php?"
@apiKey=["1111111111111111111111"]

def testRunner(url,apiKey)
	puts "Checking URL: "+url
	runnerUrl=@queryNode+""+@runTest
	baseurl=command=runnerUrl+"k="+apiKey+"&url="+url+'&fvonly=1&f=json&mobile=1&mobileDevice=AndroidOne'#&location='
	response = Net::HTTP.get(URI(baseurl))
	checkResponse(url,response)
end

def getResults(filename,type,csv_url)
	puts "Retrieving results..."
	uri = URI.parse(csv_url)
	http = Net::HTTP.new(uri.host, uri.port)
	req = Net::HTTP::Post.new(uri.path)
	while((csv_content = http.request(req)).class == Net::HTTPNotFound)
		sleep 5
	end
	raw_results = CSV.parse(csv_content.body, {:headers => true, :return_headers => true, :header_converters => :symbol, :converters => :all})
	fw=File.new(@dir+filename+"_"+type+".csv","w")
	fw.puts raw_results
	fw.close
end

def checkResponse(url,resp)
	print "Checking reponse..."
	response=JSON.parse(resp)
	if  response["statusCode"]==200
		puts "OK"
		data=response["data"]
	#response.each{|key, value| puts key.to_s+"=>"+value.to_s}
		getResults(url,"detail",data["detailCSV"]) if data["detailCSV"]!=nil
		getResults(url,"summary",data["summaryCSV"]) if data["summaryCSV"]!=nil
	else
		puts "ERROR: "+response["statusCode"].to_s+" "+response["statusText"].to_s
	end
end

inputFile=ARGV[0]
@dir=ARGV[1]
abort "Error: Wrong input" if inputFile==nil or not File.exists? inputFile
if @dir==nil
	if inputFile.include? "/"
		@dir=inputFile.split("/").first
	end
end
puts @dir.to_s
File.foreach(inputFile) {|line|
	testRunner(line.chop,@apiKey[0])
}
