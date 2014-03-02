require './models'
require './worker'

configure do
  @@range = (0..1000).to_a
end

get "/" do
  haml :index
end

get "/workers" do
  @workers = Celluloid::Actor.all
  @programs = Program.all
  haml :workers
end

post "/workers/start" do
  num = @@range.delete @@range.sample
  name = "#{params[:channel]}-#{"%03d" % num}"  
  program = Program[params[:program]]  
  worker = Worker.new params[:channel], program
  Celluloid::Actor[name.to_sym] = worker
  redirect "/workers"
end

get "/workers/stop/:id" do
  worker = Celluloid::Actor[params[:id].to_sym]
  worker.terminate
  redirect "/workers"
end

get "/workers/clone/:id" do
  worker = Celluloid::Actor[params[:id].to_sym]
  num = @@range.delete @@range.sample
  name = "#{worker.channel_name}-#{"%03d" % num}"  
  clone = Worker.new worker.channel_name, worker.program
  Celluloid::Actor[name.to_sym] = clone
  redirect "/workers"
end

get "/programs" do
  @programs = Program.all
  haml :programs  
end

get "/programs/edit/:id" do
  @program = Program[params[:id]]
  haml :"programs.edit"    
end

get "/programs/new" do
  haml :"programs.new"  
end

post "/programs" do
  unless program = Program[params[:id]]
    program = Program.create
  end
  program.update name: params[:name], code: params[:code]
  redirect "/programs"
end

get "/programs/delete/:id" do
  Program[params[:id]].destroy
  redirect "/programs"
end
