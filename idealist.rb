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

  property :id, Serial    # primary serial key
  property :body, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_length_of :body, :minimum => 1

  belongs_to :list, :required => false

  def to_json(*a)
    JSON.pretty_generate({:id => id, :list_id => list.id, :body => body, :created_at => created_at, :updated_at => updated_at})
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

get '/api/lists/?', :provides => 'json' do
  @lists = List.all(:order => [:id.desc])
  @lists.to_ary.to_json
end

post '/api/lists/?' do
  data = JSON.parse(request.body.read.to_s)
  if data.nil? || !data.has_key?('name')
    status 400
  else
    list = List.new(:name => data['name'])
    list.created_at = Time.now
    list.updated_at = Time.now
    list.save
    status 201
  end
end

put '/api/lists/?' do
  data = JSON.parse(request.body.read.to_s)
  if data.nil? || !data.has_key?('name') || !data.has_key?('id')
    status 400
  else
    list = List.get(data['id'])
    if list
      list.name = data['name']
      list.updated_at = Time.now
      list.save
      status 200
    else
      status 404
    end
  end
end

delete '/api/lists/?' do
  data = JSON.parse(request.body.read.to_s)
  if data.nil? || !data.has_key?('id')
    status 400
  else
    list = List.get(data['id'])
    if list
      list.destroy
      status 200
    else
      status 404
    end
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
  @list.save
  redirect '/lists'
end

get '/lists/edit/:id/?', :provides => 'html'  do
  @list = List.get(params[:id])
  if @list
    haml :"lists/edit"
  else
    redirect '/lists'
  end
end

post '/lists/update/:id/?' do
  @list = List.get(params[:id])
  @list.name = params[:list_name]
  @list.save
  redirect '/lists'
end

delete '/lists/:id/?' do
  @list = List.get(params[:id])
  @list.destroy
  redirect '/lists'
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
  redirect "/lists/#{@list.id}/thoughts"
end

get '/lists/:listId/thoughts/:id/?', :provides => 'html' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought
    haml :"thoughts/show"
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

get '/lists/:listId/thoughts/edit/:id/?', :provides => 'html' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought
    haml :"thoughts/edit"
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

post '/lists/:listId/thoughts/update/:id/?' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  @thought.body = params[:thought_body]
  if @thought.save
    redirect "/lists/#{@list.id}/thoughts/#{@thought.id}"
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

delete '/lists/:listId/thoughts/:id/?' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  @thought.destroy
  redirect "/lists/#{@list.id}/thoughts"
end