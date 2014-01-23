require 'rubygems'  
require 'Asana'
require 'sinatra'  
require 'Haml'
require 'Typhoeus'
require 'json'

# Asana.configure do |client|
#   client.api_key = '4tuQrdX.5djpapCXlKooicNrUgx0zbeY'
# end

$key = ""  #can put your API key in here if you want - but should pass it in through a form
$tag = ""  #this will be the tag you want to display

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
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: $key).body)

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



          #gets stories for comments - I don't think we'll use this in this Milestones version, but will use for individual project pages.

          # if stories.any?  
          #   stories["data"].each do |story|
          #     if story["type"] == "comment"
          #       collected_comments.push(story)
          #     end
          #   end
          # end
    #should I add subtasks?  Can I?
  end

  haml :personal, :layout => false
end  


get '/userInput' do
  
  haml :input, :layout => false
end

post '/userInput' do

  $key = params[:key]
  $tag = params[:tag]
  redirect to('/Milestones')
end

get '/test' do
  @test_param = $key
  @test_param2 = $tag
  haml :test, :layout => false
end


get '/Milestones' do 
  
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: $key).body)

  active_projects = all_projects["data"].select { |e| e["color"] == "dark-green" }

  @active_project_data = [] #an array to be filled with hashes for each project

  $asana_tag = $tag #will make this a user input option later

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,followers,due_on,assignee,tags,completed", userpwd: $key).body)
    
    #parse the list for milestones
    tags = all_tasks["data"].select { |task| task["tags"].length >= 1 && task["completed"] == false} 

    #show comments too??  or just update in notes?

    #some arrays we are gonna need, at least temporarily
    filtered_tasks = []
    collected_comments = []

    if tags.any?
      
      #strip out all the task ids
      task_id = tags.map { |task| task["id"].to_s }

      #get tag info for each task
      task_id.each do |id|
        tag_info = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: $key).body) #try an option_expand here from Asana  #returns an hash "data" with it's value as an array

        #check the name of the tag
        if tag_info["data"].any? {|tag| tag["name"] == $asana_tag}   

          #if it's the one we want, put it in the filtered_tasks array #would any? work here? "data"].any? {|tag|["name"] == "MILESTONE"} 

          currentTask = tags.find { |task| task["id"] == id.to_i} #returns task object, a hash

          stories = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/stories?opt_fields=type,text", userpwd: $key).body) #returns data array with hashes in each index, one for each comment.  "created by" key has hash as value, and includes "id" and "name"   

          #clean up notes
          currentTask["notes"].gsub!("\n", "<br/>")


          #a hack or messy way to get current task into an array, since my function below takes an array
          currentTaskArray = []
          currentTaskArray.push(currentTask)


          #gets followers into task
          followers = [] #to get filled with strings
          get_followers_from_tasks(currentTaskArray, followers) #returns a bunch of strings and puts them in an array
          currentTask["follower_names"] = followers 

          filtered_tasks.push(currentTask) #push the task to the filtered array

          #set some kind of flag that says this project actually has a task in a project with a tag you asked for, and should display that project. If not, don't push in this project...
        end  

      end #end of task loop

      #put that data into an array, for looping through in HAML
      project["tasks"] = filtered_tasks   #.sort_by! {| task | task["due_on"] } 

      #at this point followers and comments are part of the project, not the specific task - FIX THAT

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