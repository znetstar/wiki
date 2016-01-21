require 'sinatra/base'
require 'json'
require "sinatra/json"
require 'redcarpet'
require 'nokogiri'
require 'date'

module Sinatra
  module API
		def markdown
			renderer = Redcarpet::Render::HTML.new(render_options = {})
			@_markdown ||= Redcarpet::Markdown.new(renderer, extensions = {})

			return @_markdown
		end

		def db
			db ||= PG.connect(:dbname => 'wiki', :user => 'zachary')
		end

    def self.registered(app)
			app.get "/api/articles" do
				page = params['page'].to_i
				_articles = db.exec("select title,id from wiki_articles limit 25 offset #{page*25}")
				articles = []
				_articles.each do |art|
					art[:url] = "/articles/#{art['id']}/view/latest"
					art['id'] = art['id'].to_i
					articles << art
				end

				result = {
					:page => page,
					:next => "/api/articles?page=#{page+1}",
					:articles => articles
				}

				json result
			end

			app.get "/api/articles" do
				redirect to('/api/articles?page=0')
			end

      app.get "/api/articles/:id" do
				_article = db.exec("select wiki_articles.title,wiki_articles.id,wiki_article_revisions.body,wiki_article_revisions.created,wiki_users.fname,wiki_users.lname,wiki_users.id as user_id from wiki_articles,wiki_users,wiki_article_revisions where wiki_articles.id=#{params['id']} and wiki_article_revisions.article_id=wiki_articles.id and wiki_users.id=wiki_article_revisions.user_id order by wiki_article_revisions.created desc limit 1;")
				if !_article.any?
					status 404
					return json :error => "Article #{params['id']} not found"
				end
				_article = _article[0]

				md = Base64.decode64(_article['body'])
				unformatted_html = markdown.render(md)
				formatted_html = Nokogiri::HTML(unformatted_html)
				plaintext = formatted_html.text

				updated = DateTime.parse(_article['created'])

				article = {
					:id => _article['id'],
					:url => "/articles/#{_article['id']}/view/latest",
					:title => _article['title'],
					:html => formatted_html,
					:plaintext => plaintext,
					:updated => updated.strftime('%Y-%m-%d %H:%M:%S'),
					:author => {
						:name => "#{_article['fname']} #{_article['lname']}",
						:url => "/authors/#{_article['user_id']}"
					}
				} 

				json article     	
      end
    end
	end
end