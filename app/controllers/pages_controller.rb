require 'restclient'

class PagesController < ApplicationController

  def index

    #if request.post?

      #redirect_to :action => 'tasks', :id => params[:token]

    #end

  end

  def tasks

    url = "http://todoist.com/API/"
    @tasks = []
    @token = params[:token]

    resp = RestClient.get(url + "getProjects", :accept => :json, :params => params)
    @projects = JSON.parse(resp.body)

    prev = Hash.new

    @projects.each do |p|

      params[:project_id] = p["id"]
      tasks = JSON.parse((RestClient.get(url + "getUncompletedItems", :accept => :json, :params => params)).body)
      tasks.each do |t|
        t["project_name"] = p["name"]
      end

      if p["indent"] > 1
        prev["tasks"].concat(tasks)
      else
        p["tasks"] = tasks
        prev = p
      end


    end


    @projects.each do |p|

      tasks = []
      task_pool = []

      unless p["tasks"].nil?
        p["tasks"].each do |task|
          task["color"] = p["color"]
          if task["due_date"].nil?
            task_pool.push(task)
          else
            date_arr = task["due_date"].split(" ")
            t = Time.local(date_arr[4],date_arr[1],date_arr[2])
            #logger.debug t.to_s + " " + task["content"]
            tasks.push(task) if t.to_date < Date.today.advance(:days => 2)
          end
        end

        if tasks.length == 0 and params[:get_more] and task_pool.length > 0
          #task = p["tasks"][rand(p["tasks"].size)]
          task = task_pool[rand(task_pool.length)]
          task["color"] = p["color"]
          params[:id] = task["id"]
          params[:date_string] = "today"
          RestClient.get(url + "updateItem", :accept => :json, :params => params)
          @tasks.push(task)
        else
          @tasks.concat(tasks)
        end

      end

    end



  end

  def snooze

    url = "http://todoist.com/API/"

    params[:date_string] = "+2"
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end

  def done

    url = "http://todoist.com/API/"

    params[:ids] = Array.new.push(params[:id])

    resp = RestClient.get(url + "updateRecurringDate", :accept => :json, :params => params)

    #logger.debug "\n\nOutput:" + JSON.parse(resp)[0]["date_string"] + "\n\n"

    unless JSON.parse(resp)[0]["date_string"].include?("every")

      RestClient.get(url + "completeItems", :accept => :json, :params => params)
      #logger.debug "\n\nOutput: Mark Complete\n\n"

    end



    redirect_to :action => 'tasks', :token => params[:token]

  end

end
