require 'rubygems'  
require 'sinatra'  
require 'haml'
require 'typhoeus'
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

#input page
get '/userInput' do
  
  haml :input, :layout => false
end

#get parameters for the app
post '/userInput' do

  $key = params[:key]
  $tag = params[:tag]
  redirect ('/Milestones')
end

#show the overview
get '/Milestones' do 
  
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name", userpwd: $key).body)

  active_projects = all_projects["data"].select { |e| e["color"] == "dark-green" }

  @active_project_data = [] #to be filled with hashes for each project

  $asana_tag = $tag #user selected tag

  #sort out data for each project
  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]

    #get all the task data, within parameters of Asana API
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,followers,due_on,assignee,tags,completed", userpwd: $key).body)
    
    #parse the list for tasks with tags
    tagged_tasks = all_tasks["data"].select { |task| task["tags"].length >= 1 && task["completed"] == false} 

    #show comments too??  or just update in notes?

    #some arrays we are gonna need, at least temporarily
    filtered_tasks = []
    collected_comments = []
    project_has_tags = false

    if tagged_tasks.any?
      
      #strip out all the tagged task's ids
      task_id = tagged_tasks.map { |task| task["id"].to_s }

      #get tag info for each task
      task_id.each do |id|
        tag_info = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: $key).body) #try an option_expand here from Asana  #returns an hash "data" with it's value as an array

        #check the name of the tag
        if tag_info["data"].any? {|tag| tag["name"] == $asana_tag}   

          currentTask = tagged_tasks.find { |task| task["id"] == id.to_i} #returns task object, a hash

          stories = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/stories?opt_fields=type,text", userpwd: $key).body) #returns data array with hashes in each index, one for each comment.  "created by" key has hash as value, and includes "id" and "name"   

          #clean up notes
          currentTask["notes"].gsub!("\n", "<br/>")


          #a hack or messy way to get current task into an array, since my function below takes an array
          currentTaskArray = []
          currentTaskArray.push(currentTask)

          #gets followers into task for "team" list
          followers = [] #to get filled with strings
          get_followers_from_tasks(currentTaskArray, followers) #returns a bunch of strings and puts them in an array
          currentTask["follower_names"] = followers 

          #put tasks in the filtered_tasks array
          filtered_tasks.push(currentTask) 

          #set some kind of flag that says this project actually has a task in a project with a tag you asked for, and should display that project. If not, don't push in this project...
        end  

      end #end of task loop

      if filtered_tasks.any?
        #put that data into an array, for looping through in HAML
        project["tasks"] = filtered_tasks   #.sort_by! {| task | task["due_on"] } ------ would be nice to have later, but needs to deal with tasks without dates.

        #since this project has some tasks with the tag we want, include that project title in the list of projects to be displayed.
        @active_project_data.push(project)
      end
      
    end

  end


  haml :personal, :layout => false
end  