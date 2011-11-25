require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'json'
require 'haml'

use Rack::MethodOverride

DataMapper.setup(:default, {
  :socket => "/Applications/MAMP/tmp/mysql/mysql.sock",
  :adapter => 'mysql',
  :database => 'idealist',
  :host => 'localhost',
  :user => 'root',
  :password => 'root'
})

class Thought
  include DataMapper::Resource

  property :id, Serial
  property :body, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_length_of :body, :minimum => 1

  belongs_to :list, :required => true

  def to_json(*a)
    JSON.pretty_generate({:id => id, :body => body, :created_at => created_at, :updated_at => updated_at})
  end
end

class List
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_length_of :name, :minimum => 1

  has n, :thoughts

  def to_json(*a)
    JSON.pretty_generate({:id => id, :name => name, :created_at => created_at, :updated_at => updated_at})
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!

## API ##

# Get all Lists
get '/api/lists/?', :provides => 'json' do
  lists = List.all(:order => [:id.desc])
  lists.to_ary.to_json
end

# Create a List
post '/api/lists/?' do
  data = JSON.parse(request.body.read.to_s)
  if data.nil? || !data.has_key?('name')
    status 400
  else
    list = List.new(:name => data['name'])
    list.created_at = Time.now
    list.updated_at = Time.now
    if list.save
      status 201
      list.to_json
    else
      status 412
    end
  end
end

# Update a List
put '/api/lists/:id/?' do
  list = List.get(params['id'])
  if list
    data = JSON.parse(request.body.read.to_s)
    if data.nil? || !data.has_key?('name')
      status 400
    else
      list.name = data['name']
      list.updated_at = Time.now
      if list.save
        status 200
        list.to_json
      else
        status 412
      end
    end
  else
    status 404
  end
end

# Delete a List
delete '/api/lists/:id/?' do
  list = List.get(params['id'])
  if list
    list.destroy
    status 200
  else
    status 404
  end
end

# Get all Thoughts on a List
get '/api/lists/:listId/thoughts/?' do
  list = List.get(params[:listId])
  if list
    Thought.all(:list_id => list.id, :order => [:id.desc]).to_ary.to_json
  else
    status 404
  end
end

# Create a Thought and add to an existing List
post '/api/lists/:listId/thoughts/?' do
  list = List.get(params[:listId])
  if list
    data = JSON.parse(request.body.read.to_s)
    if data.nil? || !data.has_key?('body')
      status 400
    else
      thought = Thought.new(:list_id => list.id, :body => data['body'])
      thought.created_at = Time.now
      thought.updated_at = Time.now
      if thought.save
        status 201
        thought.to_json
      else
        status 412
      end
    end
  else
    status 404
  end
end

# Update a Thought on an existing List
put '/api/lists/:listId/thoughts/:id/?' do
  list = List.get(params[:listId])
  thought = Thought.get(params[:id])
  if list && thought && thought.list.id === list.id
    data = JSON.parse(request.body.read.to_s)
    if data.nil? || !data.has_key?('body')
      status 400
    else
      thought.body = data['body']
      thought.updated_at = Time.now
      if thought.save
        status 200
        thought.to_json
      else
        status 412
      end
    end
  else
    status 404
  end
end

# Delete a Thought on an existing list
delete '/api/lists/:listId/thoughts/:id/?' do
  list = List.get(params[:listId])
  thought = Thought.get(params[:id])
  if list && thought && thought.list.id === list.id
    thought.destroy
    status 200
  else
    status 404
  end
end

## HTML ##

get '/lists/?', :provides => 'html' do
  @lists = List.all(:order => [:id.desc])
  haml :"lists/index"
end

get '/lists/new/?' do
  haml :"lists/new"
end

post '/lists/create/?' do
  @list = List.new(:name => params[:list_name])
  if @list.save
    redirect '/lists/'
  else
    redirect '/lists/new/'
  end
end

get '/lists/edit/:id/?', :provides => 'html'  do
  @list = List.get(params[:id])
  haml :"lists/edit"
end

post '/lists/update/:id/?' do
  @list = List.get(params[:id])
  @list.name = params[:list_name]
  if @list.save
    redirect '/lists/'
  else
    redirect "/lists/edit/#{@list.id}/"
  end
end

delete '/lists/:id/?' do
  @list = List.get(params[:id])
  @list.destroy
  redirect '/lists/'
end

get '/lists/:listId/thoughts/?', :provides => 'html'  do
  @list = List.get(params[:listId])
  @thoughts = Thought.all(:list_id => @list.id, :order => [:id.desc])
  haml :"thoughts/index"
end

get '/lists/:listId/thoughts/new/?', :provides => 'html' do
  @list = List.get(params[:listId])
  haml :"thoughts/new"
end

post '/lists/:listId/thoughts/create' do
  @list = List.get(params[:listId])
  @thought = Thought.new(:list_id => params[:listId], :body => params[:thought_body])
  if @thought.save
    redirect "/lists/#{@list.id}/thoughts/"
  else
    redirect "/lists/#{@list.id}/thoughts/new/"
  end
end

get '/lists/:listId/thoughts/:id/?', :provides => 'html' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought.list.id === @list.id
    haml :"thoughts/show"
  else
    redirect "/lists/#{@list.id}/thoughts/"
  end
end

get '/lists/:listId/thoughts/edit/:id/?', :provides => 'html' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought.list.id === @list.id
    haml :"thoughts/edit"
  else
    redirect "/lists/#{@list.id}/thoughts/"
  end
end

post '/lists/:listId/thoughts/update/:id/?' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought.list.id === @list.id
    @thought.body = params[:thought_body]
    if @thought.save
      redirect "/lists/#{@list.id}/thoughts/#{@thought.id}/"
    else
      redirect "/lists/#{@list.id}/thoughts/edit/#{@thought.id}/"
    end
  else
    redirect "/lists/#{@list.id}/thoughts/"
  end
end

delete '/lists/:listId/thoughts/:id/?' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought.list.id === @list.id
    @thought.destroy
  end
  redirect "/lists/#{@list.id}/thoughts/"
end
