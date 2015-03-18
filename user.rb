require 'bcrypt'
require 'byebug'

class User < ActiveRecord::Base
	validates_uniqueness_of :username

	def self.encrypt_password(password)
		BCrypt::Password.create(password)
	end

	def authenticate(password)
		BCrypt::Password.new(self.encrypted_password) == password
	end

	def increase_login_count
		self.sign_in_count += 1
		save
	end

	def log_last_sign_in_time
		self.last_sign_in_at = Time.now
		save
	end
end