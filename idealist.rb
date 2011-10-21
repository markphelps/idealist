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
    JSON.pretty_generate({:id => id, :body => body, :created_at => created_at, :updated_at => updated_at})
  end
end

class List
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  validates_length_of :name, :minimum => 1

  has n, :thoughts

  def to_json(*a)
    JSON.pretty_generate({:id => id, :name => name})
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

get '/thoughts' do
  @thoughts = Thought.all(:order => [:id.desc])
  respond_to do |wants|
    wants.html { haml :"thoughts/index" }
    wants.json { @thoughts.to_ary.to_json }
  end
end

get '/thoughts/new' do
  haml :"thoughts/new"
end

post '/thoughts/create' do
  @thought = Thought.new(:body => params[:thought_body])
  @thought.save
  redirect '/thoughts'
end

get '/thoughts/:id' do
  @thought = Thought.get(params[:id])
  if @thought
    respond_to do |wants|
      wants.html { haml :"thoughts/show" }
      wants.json { @thought.to_json }
    end
  else
    redirect '/thoughts'
  end
end

get '/thoughts/edit/:id' do
  @thought = Thought.get(params[:id])
  if @thought
    haml :"thoughts/edit"
  else
    redirect '/thoughts'
  end
end

post '/thoughts/update/:id' do
  @thought = Thought.get(params[:id])
  @thought.body = params[:thought_body]
  if @thought.save
    haml :"thoughts/show"
  else
    redirect '/thoughts'
  end
end

delete '/thoughts/:id' do
  @thought = Thought.get(params[:id])
  if @thought.destroy
    redirect '/thoughts'
  else
    haml :"thoughts/show"
  end
end