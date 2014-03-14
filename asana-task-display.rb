require 'rubygems'  
require 'sinatra'  
require 'haml'
require 'typhoeus'
require 'json'
require './tasks' #get the Tasks class
require 'omniauth-asana'
require 'ostruct'
require './Asana_Config'

$ASANA_CLIENT_ID = ENV['ASANA_CLIENT_ID']  # '9964655308375'                     
$ASANA_CLIENT_SECRET =  ENV['ASANA_CLIENT_SECRET'] #'71afb3cc7e0a4c9cdf65bb1706430118'                     


# set :port, Asana_Config::PORT

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :asana, $ASANA_CLIENT_ID, $ASANA_CLIENT_SECRET 
end

$tag = ""      #this will be the tag you want to display
$color = ""    #project color
$user = ""     #use ID, for now - later name
$alt_user = ""
$token = ""
$tasks = Asana::Tasks.new  #make an instance of the tasks class

$redirect_location = ""


######################################################   Routes


#Asana Connect page
get '/' do
  $redirect_location = "success"
  redirect '/auth/asana'
  # How it used to be when I checked to see if Auth was true first.
  # if session[:auth]
  #   redirect '/success'
  # else
  #   redirect '/auth/asana'
  # end

end

#sign in
get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  session[:auth] = auth.credentials
  session[:uid] = auth.uid
  session[:user] = auth.info
  $user = session[:uid]
  $token = session[:auth][:token]
  redirect "/#{$redirect_location}" 
end


get '/auth/failure' do
  raise StandardError, params
end

get '/logout' do
  session.destroy
  redirect '/'
end


#input page
get '/success' do
  # $redirect_location = "/success"
  # redirect '/auth/asana'
  #get list of user names and ids and store them in an array (with hashes inside)
  all_users = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/users/?opt_fields=id,name",  headers: {Authorization: "Bearer " + session[:auth][:token]}).body)
  #then loop through that array in haml

  haml :input, :layout => false, :locals => {:all_users => all_users}
end

get '/complete_task/:id' do |id|
  #get the tasks id
  task_id = id
  #post the call to complete the task
  $tasks.complete_task(task_id)
  #go get tasks again, this time updated
  redirect ('/user')
end

#get parameters for the overview app
post '/' do
  
  $tag = params[:tag]
  $color = ""
  if params[:project_color] != "none"
    $color = params[:project_color]
  else
    $color = nil
  end
  redirect ('/overview')
end

post '/user_view' do
  $user = session[:uid]
  $color = ""
  if params[:project_color] != "none"
    $color = params[:project_color]
  else
    $color = nil
  end
  redirect ('/user')

end

post '/alt_user_view' do
  $color = ""
  if params[:project_color] != "none"
    $color = params[:project_color]
  else
    $color = nil
  end
  $user = params[:pick_a_user]

  redirect ('/user')
end

#show the overview
get '/overview' do 
  redirect_location = "/overview"
  # all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,follower_names", userpwd: $key).body)
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name",  headers: {Authorization: "Bearer " + session[:auth].token}).body)

  active_projects = all_projects["data"].select { |e| e["color"] == $color }

  @active_project_data = [] #to be filled with hashes for each project

  $asana_tag = $tag #user selected tag

  #sort out data for each project
  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]

    #get all the task data, within parameters of Asana API
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,followers,due_on,assignee,tags,completed",  headers: {Authorization: "Bearer " + session[:auth].token}).body)
    
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
        tag_info = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags",  headers: {Authorization: "Bearer " + session[:auth].token}).body) #try an option_expand here from Asana  #returns an hash "data" with it's value as an array

        #check the name of the tag
        if tag_info["data"].any? {|tag| tag["name"] == $asana_tag}   

          currentTask = tagged_tasks.find { |task| task["id"] == id.to_i} #returns task object, a hash

          stories = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/stories?opt_fields=type,text",  headers: {Authorization: "Bearer " + session[:auth].token}).body) #returns data array with hashes in each index, one for each comment.  "created by" key has hash as value, and includes "id" and "name"   

          #clean up notes
          currentTask["notes"].gsub!("\n", "<br/>")


          #a hack or messy way to get current task into an array, since my function below takes an array
          currentTaskArray = []
          currentTaskArray.push(currentTask)

          #gets followers into task for "team" list
          followers = [] #to get filled with strings
          $tasks.get_followers_from_tasks(currentTaskArray, followers) #returns a bunch of strings and puts them in an array
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


  haml :overview, :layout => false
end  

#user page
get '/user' do 
  # redirect_location = "/user"
  # redirect '/auth/asana'

  user_id = $user.to_i
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name",  headers: {Authorization: "Bearer " + session[:auth].token}).body)

  if $color != nil 
    active_projects = all_projects["data"].select { |e| e["color"] == $color }
  else
    active_projects = all_projects["data"]
  end
    
  @active_project_data = []

  active_projects.each do |e| 

    #make a new hash to store project data in
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]
    all_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + e["id"].to_s + "/tasks?opt_fields=name,notes,due_on,assignee,completed,tags&opt_expand=name",  headers: {Authorization: "Bearer " + session[:auth].token}).body)
    
    #parse the full list of tasks to see if there are any for the user
    tasksForUser = all_tasks["data"].select { |task| task["assignee"] != nil && task["completed"] == false && task["assignee"]["id"] == user_id}

    #check to see if this user has any tasks assigned to them in this project.  If they do, then do this push.
    if tasksForUser.any?

      #orders tasks by date
      rearranged_tasks = $tasks.order_tasks_by_date(tasksForUser)
      

      #check through tasks for subtasks, and add them to the task, if they exist
      rearranged_tasks.each do |task|
        subtasks = []
        $tasks.get_subtasks(task["id"], subtasks)
        if subtasks.length >= 1
          task["subtasks"] = $tasks.order_tasks_by_date(subtasks) #an array of hashes
        end
      end

      #put that data into an array, for looping through in HAML
      project["tasks"] = rearranged_tasks

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

  haml :personal_user, :layout => false
end 