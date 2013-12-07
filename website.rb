require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end

x = 0

#get workspaces from Asana
workspaces = Asana::Workspace.all
# workspaces.test = yellow

#get users from Asana
users = Asana::User.all

#list projects


def printWorkspaceNames(name)
   workspaceName = name
   puts workspaceName
end

def getWorkspaceNames(workspaces)
	workspaces.each do |w|
    workspaceName = w.name
    puts workspaceName
  end
end

get '/' do  
  haml :index, :locals => {:workspaces => workspaces}
end  

get '/projects/:id' do |id| 
  # haml :index
  id.reverse
end  

get '/about' do

  haml :about, :locals => {:workspaces => workspaces, :hello => "hiya"}
end  

get '/users' do  
  haml :about 
end  

#haml :about, :locals => {:hello => workspaceNameTest}