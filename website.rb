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


#get single project
# def getSingleProject(proj, tag1, tag2)
#   tasks = proj.tasks
#   tasks.each do |t|
#     t.tags.each do |tags|
#       if tags.name == tag1
#         puts t.name
#         puts t.notes
#         puts t.due_on
#       end
#       if tags.name == tag2
#         puts t.name
#         puts t.assignee.name
#         puts t.notes
#         #eventually add comments?
#       end
#     end
#   end
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
  @milestone = @project.tasks.find { |task| task.tags.any? { |tag| tag.name == "MILESTONE" } }
  # @tasks = @project.tasks.select { |task| Date.parse(task.due_on) <= Date.parse(@milestone.due_on)}
  
  haml :project
end 

get '/about' do
  haml :about
end  

get '/Loren' do
  haml :Loren, :layout => false
end  
