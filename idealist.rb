require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'

DataMapper.setup(:default, {
  :socket => "/Applications/MAMP/tmp/mysql/mysql.sock",
  :adapter => 'mysql',
  :database => 'idealist',
  :host => 'localhost',
  :user => 'root',
  :password => 'root'
})

class Idea
  include DataMapper::Resource

  property :id,         Serial    # primary serial key
  property :summary,    String
  property :body,       Text
  property :created_at, DateTime
  property :updated_at, DateTime
  
  validates_presence_of :summary
  validates_length_of :summary, :minimum => 1
end

DataMapper.auto_upgrade!

get '/' do
  @ideas = Idea.all
  if @ideas
    haml :index
  end
end

get '/new' do
  haml :new
end

post '/create' do
  @idea = Idea.new(:summary => params[:idea_summary], :body => params[:idea_body])
  if @idea.save
    redirect "/#{@idea.id}"
  else
    redirect '/new'
  end  
end

get '/:id' do
  @idea = Idea.get(params[:id])
  if @idea
    haml :show
  else
    redirect '/'
  end  
end
