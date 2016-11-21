require_relative 'path_helper'

project_path = ProjectPath.get_project_path
puts "project_path=#{project_path}"
God.watch do |w|
  w.name = 'ddns'
  w.start = "ruby #{project_path}lib/ddns.rb"
  w.keepalive
  w.log = "#{project_path}lib/god.log"
end
