module Wiki
	class Server < Sinatra::Base
		def db 
			@db ||= PG.connect dbname: 'wiki', user: 'zachary'
		end

		get '/' do
			erb :index
		end
	end
end