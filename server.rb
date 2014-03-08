require './models'
require './worker'

configure do
  @@range = (0..1000).to_a
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'my_saucy_secret'
  set :protection, except: :session_hijacking  
end

helpers Loggable

get "/login" do  
  haml :login, layout: false
end

get "/logs" do
  require_login
  page = params[:page] || 1
  page_size = params[:page_size] || 10
  @logs = Log.reverse_order(:created_at).paginate(page.to_i, page_size.to_i)
  haml :logs
end

post "/auth" do
  if authenticate(params[:email], params[:password])
    info "#{params[:email]} has logged in."
    session[:user] = params[:email]
    redirect "/"
  else
    raise "Incorrect username or password"
  end
end

get "/" do
  require_login
  haml :index
end

get "/logout" do
  session.clear
  redirect "/login"
end

get "/workers" do
  require_login
  @workers = Celluloid::Actor.all
  @programs = Program.all
  haml :workers
end

post "/workers/start" do
  require_login
  num = @@range.delete @@range.sample
  name = "#{params[:channel]}-#{"%03d" % num}"  
  program = Program[params[:program]]    
  variables = Hash[params[:variable].reject(&:empty?).zip params[:value].reject(&:empty?)]  
  worker = Worker.new params[:channel], program, variables
  Celluloid::Actor[name.to_sym] = worker
  redirect "/workers"
end

get "/workers/stop/:id" do
  require_login
  worker = Celluloid::Actor[params[:id].to_sym]
  worker.terminate
  redirect "/workers"
end

get "/workers/clone/:id" do
  require_login
  worker = Celluloid::Actor[params[:id].to_sym]
  num = @@range.delete @@range.sample
  name = "#{worker.channel_name}-#{"%03d" % num}"  
  clone = Worker.new worker.channel_name, worker.program, worker.variables
  Celluloid::Actor[name.to_sym] = clone
  redirect "/workers"
end

post "/workers/modify" do
  require_login
  worker = Celluloid::Actor[params[:id].to_sym]
  worker.variables = Hash[params[:variable].reject(&:empty?).zip params[:value].reject(&:empty?)]
  redirect "/workers"  
end

get "/programs" do
  require_login
  @programs = Program.all
  haml :programs  
end

get "/programs/edit/:id" do
  require_login
  @program = Program[params[:id]]
  haml :"programs.edit"    
end

get "/programs/new" do
  require_login
  haml :"programs.new"  
end

post "/programs" do
  require_login
  unless program = Program[params[:id]]
    program = Program.create
    
  end
  program.update name: params[:name], code: params[:code]
  redirect "/programs"
end

get "/programs/delete/:id" do
  require_login
  Program[params[:id]].destroy
  redirect "/programs"
end


def require_login      
  redirect "/login" unless session[:user]
end

def authenticate(email, password)
  RestClient.post "http://localhost:8108/authenticate", email: email, password: password
end