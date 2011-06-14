require 'restclient'

class PagesController < ApplicationController

  def index

    url = "http://todoist.com/API/"
    params[:token] = "b6eaa5f86a7fff727722ab3fcfa07db236ff651f"
    @tasks = []


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

      unless p["tasks"].nil?
        task = p["tasks"][rand(p["tasks"].size)]
        task["color"] = p["color"]
        @tasks.push(task)
      end

    end



  end

end
