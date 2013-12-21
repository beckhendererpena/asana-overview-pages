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
# allProjects = Asana::Project.all

# Get all projects in a given workspace
# workspace = Asana::Workspace.find("593447651003")
# projects = workspace.projects

#get users from Asana
# users = Asana::User.all

def getAssignedTasksFromProject(projectId)

  # return an array with all the tasks that are assigned to someone
  allAssignedTasks = Asana::Project.find(projectId).tasks.select { |task| task.assignee != nil }
  
  # get user list for this project
  # getUserListFromProject(allAssignedTasks) #returns array of users

  # for each user in an array, print their name and a list of tasks ---- probably done in HAML
  getUserListFromProject(allAssignedTasks).each do |user|  
    puts user.to_s #might want to send users list to haml too?  instead of putsing here.
    allAssignedTasks.each do |task|
      if task.assignee.name == user
        puts task.name #get rid of puts here when transferring
      end
    end
  end
  
end

def getUserListFromProject(taskList)
  usersInThisProject = []
  taskList.sort_by {|i| i.assignee.name}.each { |task| usersInThisProject << task.assignee.name }
  return usersInThisProject.uniq!
end


#run ----->

#print all project names to the screen
# puts getActiveProjects(allProjects).map { |e| e.name }
# puts date
# getSingleProject(asanaProject, "MILESTONE", "overview")

getAssignedTasksFromProject("1845896782580")

