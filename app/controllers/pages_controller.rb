require 'restclient'

class PagesController < ApplicationController

  def index
    
  end


  def tasks

    url = "http://todoist.com/API/"

    #tasks to display
    @tasks = []
    
    @token = params[:token]

    #get projects
    resp = RestClient.get(url + "getProjects", :accept => :json, :params => params)
    @projects = JSON.parse(resp.body)

    #a reference to the previous project
    prev = Hash.new

    @projects.each do |p|

      #get all tasks for this project
      params[:project_id] = p["id"]
      tasks = JSON.parse((RestClient.get(url + "getUncompletedItems", :accept => :json, :params => params)).body)
      
      #set the project name on each task for use later
      tasks.each do |t|
        t["project_name"] = p["name"]
      end

      #if this is a sub project
      if p["indent"] > 1
        #combine tasks with previously collected tasks
        prev["tasks"].concat(tasks)
      #new project not a sub
      else
        p["tasks"] = tasks
        #set prevous project reference to this project
        prev = p
      end

    end

    #now you have a list of all projects and uncompleted tasks for each

    @projects.each do |p|

      #holds tasks for this project that want to display
      tasks = []

      #tasks without a due date
      task_pool = []
      priority_task_pool = []

      recurring = 0

      prev = Hash.new

      #if tasks exist for this project
      unless p["tasks"].nil?

        p["tasks"].each do |task|

          task["sub_tasks"] = []
          task["days_overdue"] = 0
          task["color"] = p["color"]

          if task["indent"] < 2          

            #no due date? - add it to the pool
            if task["due_date"].nil?
              if task["priority"] > 1
                priority_task_pool.push(task)
              else
                task_pool.push(task)
              end
            #get tasks that have a due date up to 1 day in the future
            else
              date_arr = task["due_date"].split(" ")
              t = Time.local(date_arr[4],date_arr[1],date_arr[2])

              #calcualte days overdue so we use in view
              days_overdue = Date.today - t.to_date
              task["days_overdue"] = days_overdue.to_i

              if t.to_date < Date.today.advance(:days => 1)
                tasks.push(task) 
                recurring += 1 if task["date_string"].include?("every")
              end
              
            end #task["due_date"].nil?

            prev = task

          else #indented task

            task["days_overdue"] = prev["days_overdue"]
            task["content"] = prev["content"] + " : " + task["content"]
            prev["sub_tasks"].push(task)

          end

        end #p["tasks"].each

        non_recurring_tasks = tasks.length - recurring

        #get a random task from pool and set date_string to today only if no non-recurring tasks collected
        if non_recurring_tasks == 0 and params[:get_more] and task_pool.length > 0
          if priority_task_pool.length > 0
            task = priority_task_pool[rand(priority_task_pool.length)]
          else  
            task = task_pool[rand(task_pool.length)]
          end
          task["color"] = p["color"]
          params[:id] = task["id"]
          params[:date_string] = "today"
          RestClient.get(url + "updateItem", :accept => :json, :params => params)
          tasks.push(task)
        end
          
        @tasks.concat(tasks)
      

      end #unless tasks nil


    end #@projects.each

  end #def


  def snooze

    url = "http://todoist.com/API/"

    params[:date_string] = "+2"
    params[:priority] = 1
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end


  def skip

    url = "http://todoist.com/API/"

    params[:date_string] = ""
    params[:priority] = 1
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end


  def done

    url = "http://todoist.com/API/"

    params[:ids] = Array.new.push(params[:id])

    if params[:recur]
      RestClient.get(url + "updateRecurringDate", :accept => :json, :params => params)
    else

    #unless JSON.parse(resp)[0]["date_string"].include?("every")
      RestClient.get(url + "completeItems", :accept => :json, :params => params)
    end

    redirect_to :action => 'tasks', :token => params[:token]

  end

end
