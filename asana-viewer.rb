require 'rubygems'  
require 'sinatra'  
require 'haml'
require 'typhoeus'
require 'json'
require './asana' #get the Tasks class
require 'omniauth-asana'
require 'ostruct'
require 'pry'
require 'pry-debugger'
# require './Asana_Config'

# $ASANA_CLIENT_ID = ENV['ASANA_CLIENT_ID']  # '9964655308375'                     
# $ASANA_CLIENT_SECRET =  ENV['ASANA_CLIENT_SECRET'] #'71afb3cc7e0a4c9cdf65bb1706430118'                     


# set :port, Asana_Config::PORT

# use Rack::Session::Cookie
# use OmniAuth::Builder do
#   provider :asana, $ASANA_CLIENT_ID, $ASANA_CLIENT_SECRET 
# end

$asana_tag = "MILESTONE"      #this will be the tag you want to display
$key = "4tuQrdX.gF4pVEShEPwEvyhThllyxAVs"
$color = "dark-green"    #project color
$user = ""     #use ID, for now - later name
$user_id = ""
$alt_user = ""
$token = ""
$project = ""
$tasks = Asana::Tasks.new  #make an instance of the tasks class

$redirect_location = ""

$usernames = {
  beck: 254224582253, 
  furey: 5357621858433,
  loren: 5025069468334,
  jens: 6158891506306,
  brody: 9144245586148,
  davidG: 7418600337492,
  ivan: 7848873077224 
}

# binding.pry
######################################################   Routes



get '/user/:name' do |name|
  
  # if name exsists in $usernames, get it's value and make it = to @user_id
  # else return something else
  @name = name
  @user_id = $usernames[name.to_sym]

  # @user_id = 254224582253 #beck


  # @user_id = id.to_i
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name",  userpwd: $key).body)

  # Gets only projects selected by control user
  if $color != nil 
    active_projects = all_projects["data"].select { |e| e["color"] == $color }  # currently hard coded to dark green
  else
    active_projects = all_projects["data"]
  end
    
  @active_project_data = []

  active_projects.each do |e| 

    #store project data
    project = Hash.new
    project["name"] = e["name"]
    project["id"] = e["id"]

    #now start sorting the tasks
    all_tasks = $tasks.get_all_tasks(e)

    #parse the full list of tasks to see if there are any for the user
    tasksForUser = $tasks.get_tasks_for_user(all_tasks, @user_id)

    #check to see if this user has any tasks assigned to them in this project.  If they do, then grab info for this project to display later.
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

      #store the users tasks, ordered by date
      project["tasks"] = rearranged_tasks


      #grab each projects milestone
      project["milestone"] = $tasks.getNextMilestone(all_tasks)  

      # project["milestone"] = $tasks.get_project_milestone(e["id"])  

      @active_project_data.push(project)
    end
          
  end

  haml :personal_user, :layout => false
end


get '/complete_task/:id/:name' do |id,name|
  #get the tasks id
  task_id = id
  #post the call to complete the task
  $tasks.complete_task(task_id)
  #go get tasks again, this time updated
  username = 
  redirect ("/user/#{name}")
end







#sign in
# get '/auth/:name/callback' do
#   auth = request.env['omniauth.auth']
#   session[:auth] = auth.credentials
#   session[:uid] = auth.uid
#   session[:user] = auth.info
#   $user = session[:uid]
#   $token = session[:auth][:token]
#   redirect "/#{$redirect_location}" 
# end


# get '/auth/failure' do
#   raise StandardError, params
# end

# get '/logout' do
#   session.destroy
#   redirect '/'
# end








#show the overview
get '/overview' do 

  # all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,follower_names", userpwd: $key).body)
  all_projects = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/?opt_fields=color,name",  headers: {Authorization: "Bearer " + session[:auth].token}).body)

  active_projects = all_projects["data"].select { |e| e["color"] == $color }

  @active_project_data = [] #to be filled with hashes for each project

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
