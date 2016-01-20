require 'bcrypt'
require 'json'
require 'securerandom'
require 'redcarpet'
require 'date'
require "base64"

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

		def tags(lim = 5)
			tags = db.exec("select tag,count(*) from wiki_article_tags group by tag order by count(*) desc limit #{lim}")
			return tags
		end

		def markdown
			renderer = Redcarpet::Render::HTML.new(render_options = {})
			@_markdown ||= Redcarpet::Markdown.new(renderer, extensions = {})

			return @_markdown
		end

		put '/article/:article_id' do
			@user = user
			md = params['body']
			db.exec("update wiki_articles set title='#{params['title']}' where id=#{params['article_id']}")
			db.exec("insert into wiki_article_revisions(article_id,user_id,body) values('#{params['article_id']}', '#{@user['id']}', '#{Base64.encode64(params['body'])}')")
			@markdown = md
			@html = markdown.render(@markdown)
			resp = {
				:title => params['title'],
				:body => @html,
				:author => {
					:fname => @user['fname'],
					:lname => @user['lname'],
					:id => @user['id']
				},
				:datetime => DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
			}
			JSON.generate resp
		end

		get '/' do
			site_info
			tags
			@articles = []
			@user = user
			erb :index
		end


		get '/articles/:article_id/:action' do
			if params['action'] == 'edit' && !user
				redirect to('/login')
			end
			site_info
			@user = user
			@action = params[:action]
			rev = db.exec("select body,user_id,created from wiki_article_revisions where article_id=#{params['article_id']} order by created desc limit 1")
			if rev.num_tuples > 0
				@markdown = Base64.decode64(rev[0]['body'])
				@html = markdown.render(@markdown)
			end
			article = db.exec("select * from wiki_articles where id=#{params['article_id']}")
			
			if article.num_tuples > 0
				@article = article[0]
				@author = db.exec("select * from wiki_users where id=#{rev[0]['user_id']}")[0]
				@date = DateTime.parse(rev[0]['created']).strftime('%F')
				@time = DateTime.parse(rev[0]['created']).strftime('%m/%d/%Y at %I:%M%p')
				erb :article
			else
				status 404
			end
		end


		get '/articles/:article_id' do
			redirect to("/articles/#{params['article_id']}/view")
		end

		get '/new_article' do
			if !user
				redirect to('/login')
			end
			article = db.exec("insert into wiki_articles(title) values('Untitled Article') returning id")[0];

			redirect to("/articles/#{article['id']}/edit");
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