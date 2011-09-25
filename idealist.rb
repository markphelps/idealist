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

  belongs_to :bucket, :required => false

  def to_json(*a)
    JSON.pretty_generate({:id => id, :body => body, :created_at => created_at, :updated_at => updated_at})
  end
end

class Bucket
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

get '/buckets' do
  @buckets = Bucket.all(:order => [:id.desc])
  respond_to do |wants|
     wants.html { haml :"buckets/index" }
     wants.json { @buckets.to_ary.to_json }
   end
end

get '/buckets/new' do
  haml :"buckets/new"
end

post '/buckets/create' do
  @bucket = Bucket.new(:name => params[:bucket_name])
  @bucket.save
  redirect '/buckets'
end

get '/buckets/edit/:id' do
  @bucket = Bucket.get(params[:id])
  if @bucket
    haml :"buckets/edit"
  else
    redirect '/buckets'
  end
end

post '/buckets/update/:id' do
  @bucket = Bucket.get(params[:id])
  @bucket.name = params[:bucket_name]
  @bucket.save
  redirect '/buckets'
end

delete '/buckets/:id' do
  @bucket = Bucket.get(params[:id])
  @bucket.destroy
  redirect '/buckets'
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