module Asana
	class Tasks

		def get_followers_from_tasks(tasks, array) #tasks == an array, array == an array
		  tasks.each do |task|
		    task["followers"].each do |follower|
		      #get user name based on user id
		      user = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/users/" + follower["id"].to_s,  userpwd: $key).body)
		      array.push(user["data"]["name"])
		    end
		  end
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

        def getNextMilestone(task_array)

        end
	end
end