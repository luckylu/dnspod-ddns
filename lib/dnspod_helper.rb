require 'uri'
require 'net/http'
require 'net/https'
require 'json'

module Dnspod
	def initialize
		conf_path = File.expand_path("../config.json")
		conf_file = File.read(conf_path)
		@conf = JSON.parse(conf_file)
	end

	def http_method(url, *params)
		uri = URI.parse(url)
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		req = Net::HTTP::Post.new(uri.path, {'User-Agent' => 'DDNS/0.0.1(646179989@qq.com'})
		req.body = {
			"login_token" => @conf['token'],
			"domain" => @conf['domain'],
			"format" => 'json'
		}
        if params.length != 0
          req.body.merge!(params[0])
        end
        req.body = URI.encode_www_form(req.body)
		res = https.request(req)
		result = JSON.parse(res.body)
	end
end
