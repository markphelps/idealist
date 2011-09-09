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

  def to_json(*a)
      {:id => id, :body => body, :created_at => created_at, :updated_at => updated_at}.to_json(*a)
  end
end

DataMapper.auto_upgrade!

get '/' do
  @thoughts = Thought.all(:order => [ :id.desc ])
  haml :index
end

get '/thoughts' do
  @thoughts = Thought.all(:order => [ :id.desc ])
  respond_to do |wants|
    wants.html { haml :index }
    wants.json { @thoughts.to_ary.to_json }
  end
end

get '/new' do
  haml :new
end

post '/create' do
  @thought = Thought.new(:body => params[:thought_body])
  @thought.save
  redirect '/'
end

get '/:id' do
  @thought = Thought.get(params[:id])
  if @thought
    respond_to do |wants|
      wants.html { haml :show }
      wants.json { @thought.to_json }
    end
  else
    redirect '/'
  end
end

get '/edit/:id' do
  @thought = Thought.get(params[:id])
  if @thought
    haml :edit
  else
    redirect '/'
  end
end

post '/update/:id' do
  @thought = Thought.get(params[:id])
  @thought.body = params[:thought_body]
  if @thought.save
    haml :show
  else
    redirect '/'
  end
end

delete '/:id' do
  @thought = Thought.get(params[:id])
  if @thought.destroy
    redirect '/'
  else
    haml :show
  end
end