require 'pathname'

module ProjectPath
	def self.get_project_path
		path = Pathname.new(File.dirname(__FILE__)).realpath.to_s
		path[0,path.length-3]
	end
end
