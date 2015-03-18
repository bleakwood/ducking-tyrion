class Guest < ActiveRecord::Base

	def self.get_new_token
		(0...8).map { (65 + rand(26)).chr }.join
	end
end