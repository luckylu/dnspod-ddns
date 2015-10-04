require 'json'
require 'open-uri'
require 'daemons'
require_relative 'dnspod_helper'

class Ddns
	attr_reader :conf
	include Dnspod

	def get_ip
        @ip = open("http://members.3322.org/dyndns/getip").read
	end

	def create_domain_or_get_domain_id
		result = http_method("https://dnsapi.cn/Domain.Create")
		if result["status"]["code"] == "1"
			@domain_id = result['domain']['id']
		elsif result["status"]["code"] == "7"
			result = http_method("https://dnsapi.cn/Domain.Info")
		    @domain_id = result['domain']['id']
		else
			raise result['status']['message']
		end
	end

	def create_record
		params = {
			"domain_id" => @domain_id, 
			"sub_domain" => @conf['sub_domain'], 
			"record_type" => "A", 
			"record_line" => "默认", 
			"value" => get_ip
		}
		result = http_method("https://dnsapi.cn/Record.Create", params)
		if result['status']['code'] == "1"
			puts "create record successfully!"
			@record_id = result['record']['id']
		else
			raise result['status']['message']
		end
	end

    def remove_record
		params = {
				"domain_id" => @domain_id,
				"sub_domain" => @conf['sub_domain']
			}
		result = http_method("https://dnsapi.cn/Record.List", params)
		if result['status']['code'] == "1"
			record_ids = []
			result['records'].each do |x|
				record_ids << x['id']
			end
			record_ids.each do |record_id|
				http_method("https://dnsapi.cn/Record.Remove",{"record_id" => record_id, "domain_id" => @domain_id})
			end
		end
    end

	def modify_record
		params = {
		"domain_id" => @domain_id, 
		"record_id" => @record_id, 
		"sub_domain" => @conf['sub_domain'],
		"record_type" => "A", 
		"record_line" => "默认", 
		"value" => get_ip
		}
		result = http_method("https://dnsapi.cn/Record.Modify", params)
	end
end
pwd = Dir.pwd
Daemons.run_proc("Ddns") do Dir.chdir(pwd)
ddns = Ddns.new
ddns.create_domain_or_get_domain_id
ddns.remove_record
ddns.create_record

    before_ip = after_ip = ddns.get_ip
	loop do
	  if before_ip != after_ip
	    ddns.modify_record
	    puts "update record!"
	    before_ip = ddns.get_ip
	    sleep (60*ddns.conf['time_interval'].to_i)
	    after_ip = ddns.get_ip
	  else
	  	puts "no need to update record!"
	  	before_ip = ddns.get_ip
	    sleep (60*ddns.conf['time_interval'].to_i)
	  	after_ip = ddns.get_ip
	   end
	end
end
