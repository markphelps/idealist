require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'json'
require 'haml'
require 'sinatra/respond_to'

Sinatra::Application.register Sinatra::RespondTo
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

get '/lists' do
  @lists = List.all(:order => [:id.desc])
  respond_to do |wants|
     wants.html { haml :"lists/index" }
     wants.json { @lists.to_ary.to_json }
   end
end

get '/lists/new' do
  haml :"lists/new"
end

post '/lists/create' do
  @list = List.new(:name => params[:list_name])
  @list.save
  redirect '/lists'
end

get '/lists/edit/:id' do
  @list = List.get(params[:id])
  if @list
    haml :"lists/edit"
  else
    redirect '/lists'
  end
end

post '/lists/update/:id' do
  @list = List.get(params[:id])
  @list.name = params[:list_name]
  @list.save
  redirect '/lists'
end

delete '/lists/:id' do
  @list = List.get(params[:id])
  @list.destroy
  redirect '/lists'
end

get '/lists/:listId/thoughts' do
  @list = List.get(params[:listId])
  @thoughts = Thought.all(:list_id => @list.id, :order => [:id.desc])
  respond_to do |wants|
    wants.html { haml :"thoughts/index" }
    wants.json { @thoughts.to_ary.to_json }
  end
end

get '/lists/:listId/thoughts/new' do
  @list = List.get(params[:listId])
  haml :"thoughts/new"
end

post '/lists/:listId/thoughts/create' do
  @list = List.get(params[:listId])
  @thought = Thought.new(:list_id => params[:listId], :body => params[:thought_body])
  @thought.save
  redirect "/lists/#{@list.id}/thoughts"
end

get '/lists/:listId/thoughts/:id' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought && @thought.list.id == @list.id
    respond_to do |wants|
      wants.html { haml :"thoughts/show" }
      wants.json { @thought.to_json }
    end
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

get '/lists/:listId/thoughts/edit/:id' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought && @thought.list.id == @list.id
    haml :"thoughts/edit"
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

post '/lists/:listId/thoughts/update/:id' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought && @thought.list.id == @list.id
    @thought.body = params[:thought_body]
    if @thought.save
      redirect "/lists/#{@list.id}/thoughts/#{@thought.id}"
    else
      redirect "/lists/#{@list.id}/thoughts"
    end
  else
    redirect "/lists/#{@list.id}/thoughts"
  end
end

delete '/lists/:listId/thoughts/:id' do
  @list = List.get(params[:listId])
  @thought = Thought.get(params[:id])
  if @thought.destroy
    redirect "/lists/#{@list.id}/thoughts"
  else
    haml :"thoughts/show"
  end
end