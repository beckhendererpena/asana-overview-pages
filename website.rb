require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end

# Get all projects
allProjects = Asana::Project.all

def getActiveProjects(projects)
  projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
end

activeProjects = getActiveProjects(allProjects)

get '/' do  
  @projects = activeProjects
  haml :index
  #:locals => {:projects => my function call that returns all projects that I can call methods on in HAML}
end  

get '/projects/:id' do |id| 
  @projects = activeProjects  
  @project = Asana::Project.find(id)
  haml :project
  #:locals => {:projects => my function call that returns all projects that I can call methods on in HAML}
end 

get '/about' do
  haml :about
end  
