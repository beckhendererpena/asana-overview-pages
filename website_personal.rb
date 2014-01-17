require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'
require 'Typhoeus'
require 'json'

# Asana.configure do |client|
#   client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
# end


#functions

def getactive_projects(projects)
  projects.select { |p|  Asana::Project.find(p.id).color == "dark-green" }
end


# def getUserListFromProject(taskList)
#   usersInThisProject = []
#   taskList.sort_by {|i| i.assignee.name}.each { |task| usersInThisProject << task.assignee.name }
#   return usersInThisProject.uniq!
# end

#run




get '/User/:id' do 
  
  user_id = params[:id].to_i
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)

  active_projects = all_projects["data"].select { |e| e["color"] == "dark-green" }

  @active_project_data = []

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,due_on,assignee,completed,tags&opt_expand=name", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)
    
    #parse the full list of tasks to see if there are any for the user
    tasksForUser = all_tasks["data"].select { |task| task["assignee"] != nil && task["completed"] == false && task["assignee"]["id"] == user_id}

    #check to see if this user has any tasks assigned to them in this project.  If they do, then do this push.
    if tasksForUser.any?
      #put that data into an array, for looping through in HAML
      project["tasks"] = tasksForUser       #.sort_by! {| task | task["due_on"] }    #.reverse!  
      @active_project_data.push(project)
    end

    #should I add subtasks?  Can I?
  end

  haml :personal, :layout => false
end  




get '/Milestones' do 
  
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)

  active_projects = all_projects["data"].select { |e| e["color"] == "dark-green" }

  @active_project_data = []

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,followers,due_on,assignee,tags,completed", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)
    
    #parse the list for milestones
    milestones = all_tasks["data"].select { |task| task["tags"].length >= 1 && task["completed"] == false} #&& milestone name is milestone... gotta figure out how to get that

    #show comments too??  or just update in notes?

    #use an if to check to see if this user has any tasks assigned to them in this project.  If they do, then do this push.
    filtered_tasks = []

    if milestones.any?
      
      #strip out all the task ids
      task_id = milestones.map { |task| task["id"].to_s }

      #get tag info for each task
      task_id.each do |id|
        tag_info = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body) #try an option_expand here from Asana

        #check the name of the tag
        if tag_info["data"][0]["name"] == "MILESTONE"   #this is limited... will not work if task has multiple tags - bleh.
          #if it's the one we want, put it in the filtered_tasks array
          filtered_tasks.push(milestones.find { |task| task["id"] == id.to_i}) 
        end

        # or like this:   filtered_tasks.push(milestones.find { |task| task["id"] == id.to_i})  if tag_info["data"][0]["name"] == "MILESTONE"

        #get followers ids - there are multiple ids possible.  figure that out.
        #check for comments

        # comments = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/stories", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body) #returns data array with hashes in each index, one for each comment.  "created by" key has hash as value, and includes "id" and "name"

        # if comments.any?
        #   comments.each do |comment|
        #     #put whole comment hash into the task info
        #   end
        # end

      end

      #put that data into an array, for looping through in HAML
      project["tasks"] = filtered_tasks   #.sort_by! {| task | task["due_on"] } 
      @active_project_data.push(project)
    end

  end


  #list followers?

#   e.g. if tag_info["data"][0]["name"] == "MILESTONE"
#           #if it's the one we want, put it in the filtered_tasks array
#           filtered_tasks.push(milestones.find { |task| task["id"] == id.to_i}) 
#         end
# you can compress that to one line
# filtered_tasks.push(milestones.find { |task| task["id"] == id.to_i})  if tag_info["data"][0]["name"] == "MILESTONE"


  haml :personal, :layout => false
end  


get '/John' do 
  
  user_id = 5357621858433
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)

  active_projects = all_projects["data"].select { |e| e["color"] == "dark-green" }

  @active_project_data = []

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,due_on,assignee,completed,tags", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)
    
    #parse the full list of tasks to see if there are any for the user
    tasksForUser = all_tasks["data"].select { |task| task["assignee"] != nil && task["completed"] == false && task["assignee"]["id"] == user_id}

    #check to see if this user has any tasks assigned to them in this project.  If they do, then do this push.
    if tasksForUser.any?
      #put that data into an array, for looping through in HAML
      project["tasks"] = tasksForUser.sort_by! {| task | task["due_on"] }    #.reverse!  
      @active_project_data.push(project)
    end

    #get Date in there for realz

    #should we add subtasks?  Can we?
  end

  haml :personal, :layout => false
end  