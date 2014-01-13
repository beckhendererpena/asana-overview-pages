require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end


#functions

def getActiveProjects(projects)
  projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
end

# def getProjectTasks(projectId)
#   project = Asana::Project.find(ProjectId)
#   project.tasks.select { |t| #tasks by something}
# end

#getting data
#running this once, rather than everytime, since it has to chrun through a lot of data per call
# activeProjects = getActiveProjects(Asana::Project.all)

def getProjectDetails(projectId, projects)
  projects.each do |ap|
    if ap.id == projectId
      #make a project object, with name, due date, notes, etc?
    end
  end 
end

#-------------------------------RUN------------->


get '/' do  
  @activeProjects = getActiveProjects(Asana::Project.all)
  haml :index
  #:locals => {:projects => my function call that returns all projects that I can call methods on in HAML}
end  

get '/projects/:id' do |id| 

  #need this for menu
  @activeProjects = getActiveProjects(Asana::Project.all) 
  
  #make sure none of these have nil values BEFORE they go to HAML!!!  STILL TO DO
  @project = Asana::Project.find(id)
  @allAssignedTasks = @project.tasks.select { |task| task.assignee != nil }
  @userList = getUserListFromProject(@allAssignedTasks)
  @milestone = @project.tasks.find { |task| task.tags.any? { |tag| tag.name == "MILESTONE" } }
  # @tasks = @project.tasks.select { |task| Date.parse(task.due_on) <= Date.parse(@milestone.due_on)}
  
  haml :project
end 

get '/about' do
  haml :about
end  

get 'users/Loren' do
  Loren = Asana::User.find("5025069468334")
  #get all projects Loren is on

  @projects = 
  @tasks = 
  haml :Loren, :layout => false
end  

get '/Beck' do 
  
  currentProjects = getActiveProjects(Asana::Project.all)
  
  @projects = [] #an array, that will get filled with hashes, with project name and project tasks in each hash.
  userId = 5357621858433

  currentProjects.each do |cp|
    #check to see if the project has any tasks for the user
    # if cp.tasks.any? { |task| task.assignee != nil && task.completed == false && task.assignee.id == userId }
      
      #put those in a hash
      h = Hash.new
      h["name"] = cp.name #returns string
      h["tasks"] = cp.tasks.select { |task| task.assignee != nil && task.completed == false && task.assignee.id == userId} #returns array

      #maybe I can find a way to not do that same loop through twice?  make the array in the if statement, and if it's length is greater than 1, then go

      @projects.push(h)  #put the hash in there
    # end
  end

  haml :personal, :layout => false
end  
