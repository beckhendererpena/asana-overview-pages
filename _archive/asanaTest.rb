require 'Asana'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end

# date = Date.today.to_s
#get workspaces from Asana
# workspaces = Asana::Workspace.all

def getActiveProjects(projects)
  projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
end

#asana-visualization project id
# asanaProject = Asana::Project.find("8820311263807")

# Get all projects
# allProjects = Asana::Project.all

# Get all projects in a given workspace
# workspace = Asana::Workspace.find("593447651003")
# projects = workspace.projects


#keeping a few of these for logic reference

# def getactive_projects(projects)
#   projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
# end


# def getUserListFromProject(taskList)
#   usersInThisProject = []
#   taskList.sort_by {|i| i.assignee.name}.each { |task| usersInThisProject << task.assignee.name }
#   return usersInThisProject.uniq!
# end

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

activeProjects = getActiveProjects(Asana::Project.all)
# Loren = Asana::User.find("5025069468334")

def getUsersTasks(projectsList, userName)
  projectsList.each do |project|
    puts project.name
    tasks = project.tasks.select { |task| task.assignee != nil && task.completed == false && task.assignee.name == userName} #how do I put it's name?  by putting in a variable first?
     
    tasks.each { |t| 
      if t.parent == nil
        puts "  *" + t.name 
        if t.due_on !=nil
          puts "   Due On:" + " " + Date.parse(t.due_on).year.to_s + " " + Date.parse(t.due_on).mon.to_s + " " + Date.parse(t.due_on).mday.to_s
        end
        puts "   NOTES:" + t.notes
        # check to see if it has subtasks. If so list them here.


        # if t.subtasks == true
        #   t.subtasks.each do |sub|
        #     puts "   --" + sub.name
        #   end
        # end
      end
    }
  end
end

getUsersTasks(activeProjects, "Beck Henderer-Pena")



