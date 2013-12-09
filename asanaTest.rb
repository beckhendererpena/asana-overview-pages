require 'Asana'

Asana.configure do |client|
  client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
end

#get workspaces from Asana
workspaces = Asana::Workspace.all

# Get all projects
projects = Asana::Project.all

# Get all projects in a given workspace
workspace = Asana::Workspace.find("593447651003")
# projects = workspace.projects

#holds all active projects, defined by color dark-green
activeProjects = []

#get users from Asana
users = Asana::User.all

def printWorkspaceName(name)
  workspaceName = name.name
  puts workspaceName
end

#to get detailed project info, you have to use the project ID and look it up on it's own.  When doing it through workspaces, 
#it just returns id and name

def getActiveProjects(proj, active)
  proj.each do |p|
    projectName = p.name
    projectId = p.id
    project = Asana::Project.find(projectId)
      #this should get out of this function, and then uncomment out the one below it
      if project.color == "dark-green"
        tasks = project.tasks
        tasks.each do |t|
          puts t.name #now only do this if it's tagged properly
        end
      end
      # if project.color == "dark-green"
      # 	active << projectName
      #   puts "#{projectName}: #{projectId}" #instead of puts-ing, I should put these to an array, and then pass that through to HAML.  or should I recreate this whole loop in HAML?
      #   puts active.last
      #   #I can probalby store the whole project object into the array form this loop too (not just the name), and then pass that through. THAT is probably the best idea.
      # end
  end
  puts active
end

#run ----->

puts "Workspace:" 
#print workspace name
printWorkspaceName(workspace)

#print all project names to the screen
getActiveProjects(projects, activeProjects)




