require 'sinatra'
require 'sinatra/activerecord'
require "sinatra/json"
require 'sinatra/assetpack'
require_relative 'user'
require_relative 'guest'
require 'byebug'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || {:adapter => "sqlite3",
  :database  => "db.sqlite3"} )

enable :sessions

helpers do
  def set_elapsed_time
  	if @user
  		@time_elapsed = (@user.reload.total_active_time / 60).floor
  	else
  		session[:first_visit_time] = Time.now unless session[:first_visit_time]
  		@time_elapsed = ((Time.now - session[:first_visit_time]) / 60).floor
  	end
  end

  def clear_guest_information
  	session.delete(:guest_token)
  end

  def store_user_in_session(user)
  	@user = user
		session[:user_id] = user.id
		clear_guest_information
		user.increase_login_count
		session[:user_active_time] = Time.now
  end
end

before do
	return if request.xhr?
	@user = User.find_by_id(session[:user_id]) if session[:user_id]
	set_elapsed_time
	if (session[:guest_token].nil? && !@user)
		guest = Guest.create(guest_token: Guest.get_new_token)
		session[:guest_token] = guest.guest_token
	end
	@guest = Guest.find_by_guest_token(session[:guest_token]) if session[:guest_token]
end

after do
	return if request.xhr?
	if @user
		@user.total_active_time += Time.now - session[:user_active_time] unless session[:user_active_time].nil?
		session[:user_active_time] = Time.now
		@user.save
	end
	@guest.touch if @guest.try(:reload) && session[:guest_token]
end

get '/live_users' do
	live_users = User.where("updated_at > ?",  5.minutes.ago).size
	live_guests = Guest.where("updated_at > ?",  5.minutes.ago).size
	json({:live_users => live_users, :live_guests => live_guests}, :encoder => :to_json, :content_type => :json)
end

get '/' do
  erb :"index"
end

get '/sign_up' do
	erb :"sign_up"
end

post '/sign_up' do
	if user = User.create(username: params[:username], encrypted_password: User.encrypt_password(params[:password]))
		@message = "注册成功"
		store_user_in_session(user)
		erb :"index"
	else
		erb :"sign_up"
	end
end

get '/sign_in' do
	erb :"sign_in"
end

post '/sign_in' do
	user = User.find_by_username(params[:username])
	if user && user.authenticate(params[:password])
		store_user_in_session(user)
		erb :"index"
	else
		@message = "用户名或密码错误"
		erb :"sign_in"
	end
end