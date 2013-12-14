require 'Asana'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end

date = Date.today.to_s
#get workspaces from Asana
# workspaces = Asana::Workspace.all

#asana-visualization project id
# asanaProject = Asana::Project.find("8820311263807")

# Get all projects
allProjects = Asana::Project.all

# Get all projects in a given workspace
# workspace = Asana::Workspace.find("593447651003")
# projects = workspace.projects

#get users from Asana
# users = Asana::User.all

#to get detailed project info, you have to use the project ID and look it up on it's own.  When doing it through workspaces, 
#it just returns id and name

def getActiveProjects(projects)
  #holds all active projects, defined by color dark-green
  # activeProjects = []
  projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
  # projects.each do |p|
  #   projectId = p.id
  #   project = Asana::Project.find(projectId)
  #     #get by color and put into array for HAML
  #     if project.color == "dark-green"  #try using select here
  #       activeProjects << project
  #     end
       
  # end
end

#rework this to take variables of what I want?  try not to puts in the function
def getSingleProject(proj, tag1, tag2)
  tasks = proj.tasks
  tasks.each do |t|
    t.tags.each do |tags|
      if tags.name == tag1
        puts t.name
        puts t.notes
        puts t.due_on
      end
      if tags.name == tag2
        puts t.name
        puts t.assignee.name
        puts t.notes
        #eventually add comments?
      end
    end
  end
end

#run ----->

#print all project names to the screen
# puts getActiveProjects(allProjects).map { |e| e.name }
puts date
# getSingleProject(asanaProject, "MILESTONE", "overview")


