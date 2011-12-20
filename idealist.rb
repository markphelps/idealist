require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'json'
require 'haml'

use Rack::MethodOverride

configure :development do
  require 'dm-mysql-adapter'
  require 'logger'

  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, {
    :socket => "/Applications/MAMP/tmp/mysql/mysql.sock",
    :adapter => 'mysql',
    :database => 'idealist_dev',
    :host => 'localhost',
    :user => 'root',
    :password => 'root'
  })
end

configure :production do
  require 'dm-postgres-adapter'
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

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

get '/', :provides => 'html' do
  redirect '/ideas/'
end

# Get all ideas
get '/ideas/?', :provides => 'html' do
  @ideas = Idea.all(:order => [:id.desc])
  haml :"ideas/index"
end

# Render new idea view
get '/ideas/new/?' do
  haml :"ideas/new"
end

# Create an idea
post '/ideas/create/?', :provides => 'html' do
  @idea = Idea.new(:body => params[:idea_body])
  if @idea.save
    redirect '/ideas/'
  else
    redirect '/ideas/new/'
  end
end

# Render idea edit view
get '/ideas/edit/:id/?', :provides => 'html' do
  @idea = Idea.get(params[:id])
  haml :"ideas/edit"
end

# Update an idea
post '/ideas/update/:id/?', :provides => 'html' do
  @idea = Idea.get(params[:id])
  @idea.body = params[:idea_body]
  if @idea.save
    redirect '/ideas/'
  else
    redirect "/ideas/edit/#{@idea.id}/"
  end
end

# Delete an idea
delete '/ideas/:id/?', :provides => 'html' do
  @idea = Idea.get(params[:id])
  @idea.destroy
  redirect '/ideas/'
end
