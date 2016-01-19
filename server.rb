require 'bcrypt'
require 'json'
require 'securerandom'

module Wiki
	class Server < Sinatra::Base
		enable :sessions

		def db
			db ||= PG.connect dbname: 'wiki', user: 'zachary'	
		end

		def meta(name, val = nil) 
			if !val
			 	db.exec("select value from wiki_meta where name='#{name}'")[0]['value']
			else
				db.exec("insert into wiki_meta(name,value) values('#{name}', '#{val}) on conflict (name) update set value=EXCLUDED.value")
			end
		end

		def site_info
			@title = meta 'title'
			@logo = meta 'logo'
		end

		def user
			token = session[:session_token]
			user = db.exec('select * from wiki_users,wiki_sessions where wiki_users.id = wiki_sessions.user_id;')
			if user.num_tuples > 0
				user[0]
			else
				nil
			end
		end

		get '/' do
			site_info
			@user = user
			erb :index
		end

		get '/logout' do
			site_info
			session.clear
			@message = 'Successfully logged out'
			erb :login
		end

		get '/login' do
			site_info
			@email = session[:email]
			erb :login
		end

		get '/login' do
			site_info
			erb :login
		end

		post '/login' do
			site_info

			begin
				user = db.exec("select * from wiki_users where email='#{params[:email]}';")
				
				if user.num_tuples > 0
					@user = user[0]
					pw = BCrypt::Password.new(@user['password'])
					if pw == params[:password]
						token = SecureRandom.uuid
						db.exec("insert into wiki_sessions(user_id, token, created) values (#{@user['id']}, '#{token}', current_timestamp);")
						session[:session_token] = token
						redirect to('/')
					else
						@error = 'Invalid password'
						@email = @user[:email]
						erb :login
					end
				else
					@error = 'An account with this email address could not be found'
					erb :login
				end
			rescue PG::Error => err
				@error = err.message
				erb :login
			end

		end

		get '/create' do
			site_info
			erb :create
		end

		post '/create' do
			site_info
			hash = BCrypt::Password.create(params[:password])
			begin
				user_id = db.exec("insert into wiki_users(fname, lname, email, password) values('#{params[:fname]}','#{params[:lname]}', '#{params[:email]}', '#{hash}') returning id;")[0]
				session[:email] = params[:email]
				redirect to('/login')
			rescue PG::Error => err
				if err.message.include? 'duplicate key'
					@error = 'An account with the submitted email address already exists'
				else
					@error = err.message
				end
				erb :create
			end
		end
	end
end