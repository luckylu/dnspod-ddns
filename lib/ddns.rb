require 'json'
require 'open-uri'
require 'daemons'
require 'logger'
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
			$logger.info {"已创建域名解析记录，域名ID：#{@domain_id}"}
		elsif result["status"]["code"] == "7"
			result = http_method("https://dnsapi.cn/Domain.Info")
		  @domain_id = result['domain']['id']
		  $logger.info {"域名解析记录已存在，域名ID：#{@domain_id}"}
		else
			raise result['status']['message']
			$logger.error {"出错了，错误信息:#{result['status']['message']}"}
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
			$logger.info {"成功创建解析记录"}
			@record_id = result['record']['id']
		else
			raise result['status']['message']
			$logger.error {"出错了，错误信息：#{result['status']['message']}"}
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
				$logger.info {"成功移除解析记录"}
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
		$logger.info {"成功更新解析记录"}
	end
end

pwd = Dir.pwd
Daemons.run_proc("ddns") do Dir.chdir(pwd)
	$logger = Logger.new(Time.now.strftime("%Y-%m-%d") + '-ddns.log', 'daily')
	$logger.level = Logger::INFO
	$logger.datetime_format = '%Y-%m-%d %H:%M:%S'
	ddns = Ddns.new
	ddns.create_domain_or_get_domain_id
	ddns.remove_record
	ddns.create_record

  before_ip = after_ip = ddns.get_ip
	loop do
	  if before_ip != after_ip
	  	$logger.info {"IP发生改变，开始更新记录"}
	    ddns.modify_record
	    before_ip = ddns.get_ip
	    sleep (60*ddns.conf['time_interval'].to_i)
	    after_ip = ddns.get_ip
	  else
	  	$logger.info {"IP没变，无需更新记录"}
	  	before_ip = ddns.get_ip
	    sleep (60*ddns.conf['time_interval'].to_i)
	  	after_ip = ddns.get_ip
	   end
	end
end
