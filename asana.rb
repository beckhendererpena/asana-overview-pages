module Asana
	class Tasks

		def get_all_tasks(project)
		  JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + project["id"].to_s + "/tasks?opt_fields=name,notes,due_on,assignee,followers,completed,tags&opt_expand=name",  userpwd: $key).body)
		end

		def get_followers_from_tasks(tasks, array) #tasks == an array, array == an array
		  tasks.each do |task|
		    task["followers"].each do |follower|
		      #get user name based on user id
		      user = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/users/" + follower["id"].to_s,  userpwd: $key).body)
		      array.push(user["data"]["name"])
		    end
		  end
		end

		def get_tasks_for_user(tasks, user_id) #takes an array
			tasks["data"].select { |task| task["assignee"] != nil && task["completed"] == false && task["assignee"]["id"] == user_id}
		end

		def complete_task(task_id)
		  Typhoeus.put("https://app.asana.com/api/1.0/tasks/" + task_id.to_s, body: '{"data": {"completed":true}}', userpwd: $key).body
		end

		def get_subtasks(task_id, subtasks)
		  task_subtasks = JSON.parse(Typhoeus.get("https://app.asana.com/api/1.0/tasks/" + task_id.to_s + "/subtasks?opt_fields=completed,name,due_on",  userpwd: $key).body) #returns a hash with an array called "data" inside
		  task_subtasks["data"].each do |t|
			if t["completed"] == false
			  subtasks.push(t) 
			end 
		  end
		end

		def order_tasks_by_date(task_array)
		  tasks_with_dates = task_array.select { |task| task["due_on"] != nil}
          task_array.delete_if { |task| task["due_on"] != nil}

          tasks_with_dates.sort_by! {| task | task["due_on"] } 

          tasks_with_dates.concat(task_array)
        end

        # def get_tag_info(ids)
       	#   ids.map do |id|
        #   	JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: $key).body)
        #   end
        # end

        def get_tag_info(id)
          	JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/tasks/" + id + "/tags", userpwd: $key).body)
        end

        # def get_project_milestone(project)
        # 	project_tasks = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/projects/" + project.to_s + "/tasks?opt_fields=name,notes,due_on,assignee,followers,completed,tags&opt_expand=name", userpwd: $key).body)
        	
        # 	milestones = []

        # 	project_tasks["data"].each do |task|
        #   	task_id = task["id"].to_s
        #   	tag_info = get_tag_info(task_id) #an_array
        #   	tag_info = tag_info["data"][0]
        #   	if tag_info != nil && tag_info["name"] == $asana_tag
        #   		milestones.push(task)
        #   	end
        #       return milestones
        #     end
        # end

        def getNextMilestone(tasks)
          tagged_tasks = tasks["data"].select { |task| task["tags"].length >= 1 && task["completed"] == false} 

          milestones = []
          
          if tagged_tasks.any?

	        tagged_tasks.each do |task|

          	  task_id = task["id"].to_s
          	  tag_info = get_tag_info(task_id) #an_array
          	  tag_info = tag_info["data"][0] #get rid of the data wrapper

	          if tag_info["name"] == $asana_tag

	          	#stick put the relevant task info in a hash
	          	milestone = Hash.new
    			milestone["name"] = task["name"]
    			milestone["id"] = task["id"]
    			milestone["due"] = task["due_on"]
    			milestone["notes"] = task["notes"]  #.gsub!("\n", "<br/>")	          
	          	#then get the relevant story info of that same task, and also put that in the hash
	          	#a hack or messy way to get current task into an array, since my function below takes an array
	            currentTaskArray = []
	            currentTaskArray.push(task)

	            #gets followers into task for "team" list
	            followers = [] #to get filled with strings
	            $tasks.get_followers_from_tasks(currentTaskArray, followers) #returns a bunch of strings and puts them in an array
	            milestone["team"] = followers
	          	#then put that whole task into an array and return it

	          	milestones.push(milestone)
	          end
	          #this should return an array full of milestones with the correct info - meh? David?
              
            end
          end

          return milestones

	    end
	end    
end