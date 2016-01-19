module Wiki
	class Server < Sinatra::Base
		def db 
			@db ||= PG.connect dbname: 'wiki', user: 'zachary'
		end

		def meta(name, val = nil) 
			if !val
			 	db.exec("select value from wiki_meta where name='#{name}'")[0]['value']
			else
				db.exec("insert into wiki_meta(name,value) values('#{name}', '#{val}) on conflict (name) update set value=EXCLUDED.value")
			end
		end

		get '/' do
			@title = meta 'title'
			@logo = meta 'logo'
			erb :index
		end

		get '/login' do
			@title = meta 'title'
			@logo = meta 'logo'
			erb :login
		end

		get '/create' do
			@title = meta 'title'
			@logo = meta 'logo'
			erb :create
		end

		post '/create' do
			db.exec("insert into wiki_meta(name,value) values('')")
		end
	end
end