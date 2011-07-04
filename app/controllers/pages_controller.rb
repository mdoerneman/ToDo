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

      recurring = 0

      #if tasks exist for this project
      unless p["tasks"].nil?

        p["tasks"].each do |task|
          task["color"] = p["color"]

          #no due date? - add it to the pool
          if task["due_date"].nil?
            task_pool.push(task)
          #get tasks that have a due date up to 1 day in the future
          else
            date_arr = task["due_date"].split(" ")
            t = Time.local(date_arr[4],date_arr[1],date_arr[2])

            if !task["date_string"].include?("every") and t < Date.today
              #clear due date
              params[:id] = task["id"]
              params[:date_string] = ""
              RestClient.get(url + "updateItem", :accept => :json, :params => params)
              
              #add to task pool
              task_pool.push(task)
            else
              if t.to_date < Date.today.advance(:days => 1)
                tasks.push(task) 
                recurring += 1 if task["date_string"].include?("every")
              end
            end

          end

        end

        non_recurring_tasks = tasks.length - recurring

        #get a random task from pool and set date_string to today only if no no-recurring tasks collected
        if non_recurring_tasks == 0 and params[:get_more] and task_pool.length > 0
          task = task_pool[rand(task_pool.length)]
          task["color"] = p["color"]
          params[:id] = task["id"]
          params[:date_string] = "today"
          RestClient.get(url + "updateItem", :accept => :json, :params => params)
          tasks.push(task)
        end
          
        @tasks.concat(tasks)
      

      end #unless


    end #@projects.each

  end #def


  def snooze

    url = "http://todoist.com/API/"

    params[:date_string] = "+2"
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end


  def skip

    url = "http://todoist.com/API/"

    params[:date_string] = ""
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end


  def done

    url = "http://todoist.com/API/"

    params[:ids] = Array.new.push(params[:id])

    resp = RestClient.get(url + "updateRecurringDate", :accept => :json, :params => params)

    unless JSON.parse(resp)[0]["date_string"].include?("every")
      RestClient.get(url + "completeItems", :accept => :json, :params => params)
    end

    redirect_to :action => 'tasks', :token => params[:token]

  end

end
