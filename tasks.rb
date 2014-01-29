module Asana
	class Tasks

		def get_followers_from_tasks(tasks, array) #tasks == an array, array == an array
		  tasks.each do |task|
		    task["followers"].each do |follower|
		      #get user name based on user id
		      user = JSON.parse(Typhoeus::Request.get("https://app.asana.com/api/1.0/users/" + follower["id"].to_s, userpwd: $key).body)
		      array.push(user["data"]["name"])
		    end
		  end
		end

		def complete_task(task_id)
		  Typhoeus.put("https://app.asana.com/api/1.0/tasks/" + task_id.to_s, body: '{"data": {"completed":true}}', userpwd: $key)
		end

	end
end