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
      {:id => id, :body => body, :created_at => created_at, :updated_at => updated_at}.to_json(*a)
  end
end

class Bucket
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  has n, :thoughts
end
DataMapper.finalize
DataMapper.auto_upgrade!

get '/thoughts' do
  @thoughts = Thought.all(:order => [ :id.desc ])
  respond_to do |wants|
    wants.html { haml :index }
    wants.json { JSON.pretty_generate @thoughts.to_ary }
  end
end

get '/thoughts/new' do
  haml :new
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
      wants.html { haml :show }
      wants.json { JSON.pretty_generate @thought }
    end
  else
    redirect '/thoughts'
  end
end

get '/thoughts/edit/:id' do
  @thought = Thought.get(params[:id])
  if @thought
    haml :edit
  else
    redirect '/thoughts'
  end
end

post '/thoughts/update/:id' do
  @thought = Thought.get(params[:id])
  @thought.body = params[:thought_body]
  if @thought.save
    haml :show
  else
    redirect '/thoughts'
  end
end

delete '/thoughts/:id' do
  @thought = Thought.get(params[:id])
  if @thought.destroy
    redirect '/thoughts'
  else
    haml :show
  end
end