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

      unless p["tasks"].nil?
        p["tasks"].each do |task|
          task["color"] = p["color"]
          tasks.push(task) if task["due_date"]
        end

        if tasks.length == 0 and params[:get_more]
          task = p["tasks"][rand(p["tasks"].size)]
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

  def skip

    url = "http://todoist.com/API/"

    params[:date_string] = ""
    RestClient.get(url + "updateItem", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :get_more => 't', :token => params[:token]

  end

  def done

    url = "http://todoist.com/API/"
    
    params[:ids] = Array.new.push(params[:id])
    RestClient.get(url + "completeItems", :accept => :json, :params => params)
    redirect_to :action => 'tasks', :token => params[:token]

  end

end
