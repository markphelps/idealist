require 'rubygems'
require 'dm-postgres-adapter'

use Rack::MethodOverride

configure :development do
  require 'logger'

  DataMapper::Logger.new(STDOUT, :debug)
end

DataMapper.setup(:default, ENV['DATABASE_URL'])

class Idea
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_length_of :body, :minimum => 1

  def to_json(*a)
    JSON.pretty_generate({:id => id, :body => body, :created_at => created_at, :updated_at => updated_at})
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

## API ##

# Get all ideas
get '/api/ideas/?', :provides => 'json' do
  ideas = Idea.all(:order => [:id.desc])
  status 200
  ideas.to_ary.to_json
end

# Get a single idea
get '/api/ideas/:id/?', :provides => 'json' do
  idea = Idea.get(params['id'])
  if !idea
    status 404
  else
    status 200
    idea.to_json
  end
end

# Create an idea
post '/api/ideas/?', :provides => 'json' do
  data = JSON.parse(request.body.read.to_s)
  if data.nil? || !data.has_key?('body')
    status 400
  else
    idea = Idea.new(:body => data['body'])
    idea.created_at = Time.now
    idea.updated_at = Time.now
    if idea.save
      status 201
      idea.to_json
    else
      status 412
    end
  end
end

# Update an idea
put '/api/ideas/:id/?', :provides => 'json' do
  idea = Idea.get(params['id'])
  if !idea
    status 404
  else
    data = JSON.parse(request.body.read.to_s)
    if data.nil? || !data.has_key?('body')
      status 400
    else
      idea.body = data['body']
      idea.updated_at = Time.now
      if idea.save
        status 200
        idea.to_json
      else
        status 412
      end
    end
  end
end

# Delete an idea
delete '/api/ideas/:id/?', :provides => 'json' do
  idea = Idea.get(params['id'])
  if !idea
    status 404
  else
    idea.destroy
    status 200
  end
end

## HTML ##

get '/' do
  redirect '/ideas/'
end

# Get all ideas
get '/ideas/?' do
  @ideas = Idea.all(:order => [:id.desc])
  haml :"ideas/index"
end

# Create an idea
post '/ideas/create/?' do
  @idea = Idea.new(:body => params[:idea_body])
  @idea.save
  redirect '/ideas/'
end

# Render idea edit view
get '/ideas/:id/?' do
  @idea = Idea.get(params[:id])
  haml :"ideas/edit"
end

# Update an idea
post '/ideas/:id/?' do
  @idea = Idea.get(params[:id])
  @idea.body = params[:idea_body]
  if @idea.save
    redirect '/ideas/'
  else
    redirect "/ideas/#{@idea.id}/"
  end
end

# Delete an idea
delete '/ideas/:id/?' do
  @idea = Idea.get(params[:id])
  @idea.destroy
  redirect '/ideas/'
end
