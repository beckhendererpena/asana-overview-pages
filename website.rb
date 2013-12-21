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
activeProjects = getActiveProjects(Asana::Project.all)

def getProjectDetails(projectId, projects)
  projects.each do |ap|
    if ap.id == projectId
      #make a project object, with name, due date, notes, etc?
    end
  end 
end

def getUserListFromProject(taskList)
  usersInThisProject = []
  taskList.sort_by {|i| i.assignee.name}.each { |task| usersInThisProject << task.assignee.name }
  return usersInThisProject.uniq!
end


# def orderTaskListByUser(taskList, userList)
#   userList.each { |user| taskList.select { |task| task.assignee.name ==   } }
# end

#-------------------------------RUN------------->


get '/' do  
  @activeProjects = activeProjects
  haml :index
  #:locals => {:projects => my function call that returns all projects that I can call methods on in HAML}
end  

get '/projects/:id' do |id| 

  #need this for menu
  @activeProjects = activeProjects 

  @project = Asana::Project.find(id)
  @allAssignedTasks = @project.tasks.select { |task| task.assignee != nil }
  @userList = getUserListFromProject(@allAssignedTasks)
  #get array of tasks by user, using user list and @allAssignedTasks.select.  can loop through that in haml along 
  #with user list to get task lists per person.
  # @sortedTaskList = orderTaskListByUser(@allAssignedTasks, @userList)
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
