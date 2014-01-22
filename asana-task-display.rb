require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'
require 'Typhoeus'
require 'json'

# Asana.configure do |client|
#   client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
# end


######################################################   Functions

def get_followers_from_tasks(tasks, array) #tasks == an array, array == an array
  tasks.each do |task|
    task["followers"].each do |follower|
      #get user name based on user id
      user = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/users/" + follower["id"].to_s, userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)
      array.push(user["data"]["name"])
    end
  end
end

######################################################   Routes

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

  @active_project_data = [] #an array to be filled with hashes for each project

  $asana_tag = "MILESTONE" #will make this a user input option later

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,followers,due_on,assignee,tags,completed", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body)
    
    #parse the list for milestones
    milestones = all_tasks["data"].select { |task| task["tags"].length >= 1 && task["completed"] == false} 

    #some arrays we are gonna need, at least temporarily
    filtered_tasks = []
    collected_comments = []

    if milestones.any?
      
      #strip out all the task ids
      task_id = milestones.map { |task| task["id"].to_s }

      #get tag info for each task
      task_id.each do |id|
        tag_info = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body) #try an option_expand here from Asana  #returns an hash "data" with it's value as an array

        #check the name of the tag
        if tag_info["data"].any? {|tag| tag["name"] == $asana_tag}   #this is limited... will not work if task has multiple tags - bleh.
          
          currentTask = milestones.find { |task| task["id"] == id.to_i} #returns task object, a hash

          stories = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/stories?opt_fields=type,text", userpwd: "4tuQrdX.5djpapCXlKooicNrUgx0zbeY:").body) #returns data array with hashes in each index, one for each comment.  "created by" key has hash as value, and includes "id" and "name"   

          #test putting something into a task
          currentTask["comments"] = collected_comments  #I think I can work it out with this...

          currentTaskArray = []
          currentTaskArray.push(currentTask)

          #gets followers into task
          followers = [] #to get filled with strings
          get_followers_from_tasks(currentTaskArray, followers) #returns a bunch of strings and puts them in an array
          currentTask["follower_names"] = followers 

          filtered_tasks.push(currentTask) #push the task to the filtered array
        end  

      end #end of task loop

      #put that data into an array, for looping through in HAML
      project["tasks"] = filtered_tasks   #.sort_by! {| task | task["due_on"] } 

      @active_project_data.push(project)
    end

  end


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

    #should we add subtasks?  Can we?
  end

  haml :personal, :layout => false
end  