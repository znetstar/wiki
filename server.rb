require 'bcrypt'
require 'json'
require 'securerandom'
require 'redcarpet'
require 'date'
require "base64"
require 'nokogiri'
require_relative 'api'

module Wiki
	class Server < Sinatra::Base
		enable :sessions

		register Sinatra::API

		def db
			db ||= PG.connect(:dbname => 'wiki', :user => 'zachary')
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
			if (defined? token) && (token != nil)
				user = db.exec("select wiki_users.* from wiki_users,wiki_sessions where wiki_sessions.token='#{token}' and wiki_users.id = wiki_sessions.user_id;")

				return (user.num_tuples > 0) ? user[0] : nil
			else
				nil
			end
		end

		def top_tags(lim = 5)
			tags = db.exec("select distinct tag,count(*) from wiki_article_tags group by tag order by count(*) desc limit #{lim}")
			return tags
		end

		def markdown
			renderer = Redcarpet::Render::HTML.new(render_options = {})
			@_markdown ||= Redcarpet::Markdown.new(renderer, extensions = {})

			return @_markdown
		end

		def article_body(id)
			rev = db.exec("select body from wiki_article_revisions where article_id=#{id} order by created desc limit 1")
			if rev.any?
				md = Base64.decode64(rev[0]['body'])
				html = markdown.render(md)
				return { :markdown => md, :html => html }
			else
				nil
			end
		end

		def articles_with_body(articles)
			arr = []
			if !articles.any?
				return arr
			end
			articles.each do |article| 
				body = article_body(article['id'])
				if body
					html = Nokogiri::HTML(body[:html])
					article['html'] = body[:html]
					article['markdown'] = body[:markdown]
					article['text'] = html.text
					article['summary'] = article['text'][0..140].gsub(/\s\w+\s*$/,'...')
					img = html.css('img').first
					if img
						article['featured_image'] = img['src']
					else
						article['featured_image'] = nil
					end
				else
					article['html'] = nil
					article['markdown'] = nil
					article['summary'] =  nil
					article['text'] = nil
					article['summary'] = nil
					article['featured_image'] = nil
				end
				arr.push(article)
			end
			arr
		end

		def card(article)
			erb :article_card, locals: { article: article } 
		end

		delete '/articles/:article_id' do
			if !user
				redirect to('/login')
			end
			db.exec("delete from wiki_article_revisions where article_id=#{params[:article_id]}")
			db.exec("delete from wiki_article_comments where article_id=#{params[:article_id]}")
			db.exec("delete from wiki_article_tags where article_id=#{params[:article_id]}")
			db.exec("delete from wiki_history where article_id=#{params[:article_id]}")
			db.exec("delete from wiki_bookmarks where id=#{params[:article_id]}")
			db.exec("delete from wiki_articles where id=#{params[:article_id]}")	
		end

		put '/article/:article_id' do
			if !user 
				status 401
				return
			end
			md = params['body']
			db.exec("update wiki_articles set title='#{params['title']}' where id=#{params['article_id']}")
			db.exec("insert into wiki_article_revisions(article_id,user_id,body) values('#{params['article_id']}', '#{user['id']}', '#{Base64.encode64(params['body'])}')")
			db.exec("delete from wiki_article_tags where article_id=#{params['article_id']}")
			
			tags = params['tags'].split(',')
			tags.each do |tag| 
				begin
					db.exec("insert into wiki_article_tags(tag,user_id,article_id) values('#{tag}'	,#{user['id']},#{params['article_id']})")
				rescue
				end
			end
			html = markdown.render(md)
			
			resp = {
				:title => params['title'],
				:body => html,
				:tags => tags,
				:author => {
					:fname => user['fname'],
					:lname => user['lname'],
					:id => user['id']
				},
				:datetime => DateTime.now.strftime('%Y-%m-%d %H:%M:%S')
			}
			JSON.generate resp
		end

		get '/' do
			site_info

			if user 
				last_visted = []
				last_visted = articles_with_body(db.exec("select distinct wiki_articles.* from wiki_articles,wiki_history where wiki_articles.id=wiki_history.article_id and wiki_history.user_id=#{user['id']}"))
			end
			articles = db.exec('select * from wiki_articles order by hits desc limit 10')
			articles = articles_with_body(articles)
			erb :index, :locals => { 
					:last_visted => ((defined? last_visted) ? last_visted : nil), 
					:tags => top_tags, 
					:user => user, 
					:articles => articles
				}
		end

		get '/search/:query' do
			site_info

			articles = db.exec("select * from wiki_articles where title ~* '#{params['query']}';")
			articles = articles_with_body(articles)
			erb :search, :locals => { 
				:last_visted => ((defined? last_visted) ? last_visted : nil), 
				:tags => top_tags, 
				:user => user, 
				:articles => articles,
				:query => params['query']
			}
		end

		get '/tag/:tag' do
			site_info

			articles = db.exec("select wiki_articles.* from wiki_articles,wiki_article_tags where wiki_article_tags.tag='#{params['tag']}' and wiki_articles.id=wiki_article_tags.article_id;")
			articles = articles_with_body(articles)
			erb :search, :locals => { 
				:last_visted => ((defined? last_visted) ? last_visted : nil), 
				:tags => top_tags, 
				:user => user, 
				:articles => articles,
				:query => params['query']
			}
		end

		get '/articles/:article_id/:action' do
			redirect to("/articles/#{params['article_id']}/#{params['action']}/latest")
		end

		get '/articles/:article_id/:action/:revision' do
			if params['action'] != 'view' && !user
				redirect to('/login')
			end
			site_info
			action = params[:action]
			rev = db.exec("select user_id,created,body from wiki_article_revisions where #{params['revision'] == 'latest' ? '' : 'id='+params['revision']+' and ' }article_id=#{params['article_id']} order by created desc limit 1")[0]
			revs = db.exec("select wiki_article_revisions.id,wiki_article_revisions.user_id,wiki_article_revisions.created,wiki_article_revisions.article_id,wiki_users.fname as author_fname,wiki_users.lname as author_lname,wiki_users.id as author_id from wiki_article_revisions,wiki_users where wiki_users.id=wiki_article_revisions.user_id and article_id=#{params['article_id']} order by created desc limit 25")
			tags = db.exec("select tag,id from wiki_article_tags where article_id=#{params['article_id']}")
			if revs.any?
				md = Base64.decode64(rev['body'])
				html = markdown.render(md)
			end
			db.exec("update wiki_articles set hits=(wiki_articles.hits + 1) where id=#{params['article_id']}")
			if user
				db.exec("insert into wiki_history(user_id,article_id,viewed) values(#{user['id']},#{params['article_id']},current_timestamp)")
			end
			article = db.exec("select * from wiki_articles where id=#{params['article_id']}")
			
			if article.num_tuples > 0
				article = article[0]
				author = revs.any? ? db.exec("select * from wiki_users where id=#{rev['user_id']}")[0] : user
				date = DateTime.parse(rev['created']).strftime('%F')
				time = DateTime.parse(rev['created']).strftime('%m/%d/%Y at %I:%M%p')
				
				erb :article, :locals => {  
					:rev_id => params['revision'], 
					:revs => revs, 
					:html => html, 
					:markdown => md, 
					:user => user, 
					:action => action, 
					:article => article, 
					:author => author, 
					:date => date, 
					:time => time, 
					:tags => (tags.any? and tags)
				}
			else
				status 404
			end
		end

		get '/history/:page' do
			site_info
			if !user
				return redirect to('/login')
			end
			_articles = db.exec("select distinct on(wiki_history.viewed,wiki_history.article_id) wiki_articles.*,wiki_history.viewed as viewed from wiki_history inner join wiki_articles on(wiki_articles.id = wiki_history.article_id) where wiki_history.user_id=#{user['id']} order by wiki_history.viewed desc limit 25 offset #{params[:page].to_i*25};")
			articles = []
			_articles.each do |his|
				articles << his
			end

			articles.uniq! { |a| a['id'] }

			erb :history, :locals => { :articles => articles, :user => user }
		end

		get '/history' do
			if !user
				return redirect to('/login')
			else
				return redirect to('/history/0')
			end
		end


		get '/articles/:article_id' do
			redirect to("/articles/#{params['article_id']}/view")
		end

		get '/new_article' do
			if !user
				return redirect to('/login')
			end
			article = db.exec("insert into wiki_articles(title) values('Untitled Article') returning id")[0];
			rev = db.exec("insert into wiki_article_revisions(user_id,article_id) values('#{user['id']}', '#{article['id']}')")
			redirect to("/articles/#{article['id']}/edit");
		end


		get '/logout' do
			site_info
			if session[:session_token]
				db.exec("delete from wiki_sessions where token='#{session[:session_token]}'")
			end
			session.clear
			message = 'Successfully logged out'
			erb :login, :locals => { :message => message }
		end

		get '/edit' do
			site_info
			email = session[:email]
			site_info
			hash = BCrypt::Password.create(params[:password])
			begin
				user_id = db.exec("update wiki_users set fname=, lname=, email=, password= values('#{params[:fname]}','#{params[:lname]}', '#{params[:email]}', '#{hash}') returning id;")[0]
				session[:email] = params[:email]
				redirect to('/login')
			rescue PG::Error => err
				if err.message.include? 'duplicate key'
					error = 'An account with the submitted email address already exists'
				else
					error = err.message
				end
				erb :edit, :locals => { :user => user, :email => email }
			end
		end

		get '/login' do
			site_info
			email = session[:email]
			erb :login, :locals => { :email => email }
		end

		get '/login' do
			site_info
			erb :login
		end

		post '/login' do
			site_info

			begin
				_user = db.exec("select * from wiki_users where email='#{params[:email]}';")
				
				if _user.num_tuples > 0
					_user = _user[0]
					pw = BCrypt::Password.new(_user['password'])
					if pw == params[:password]
						token = SecureRandom.uuid
						db.exec("insert into wiki_sessions(user_id, token, created) values (#{_user['id']}, '#{token}', current_timestamp);")
						session[:session_token] = token
						redirect to('/')
					else
						error = 'Invalid password'
						email = _user[:email]
						erb :login, :locals => { :email => email, :err => error  }
					end
				else
					error = 'An account with this email address could not be found'
					erb :login, :locals => { :err => error  }
				end
			rescue PG::Error => err
				error = err.message
				erb :login, :locals => { :err => error  }
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
					error = 'An account with the submitted email address already exists'
				else
					error = err.message
				end
				erb :create, :locals => { :err => error  }
			end
		end
	end
end