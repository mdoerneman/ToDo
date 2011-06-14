require 'restclient'

class PagesController < ApplicationController

  def index

    url = "http://todoist.com/API/"
    params[:token] = "b6eaa5f86a7fff727722ab3fcfa07db236ff651f"
    @tasks = []


    resp = RestClient.get(url + "getProjects", :accept => :json, :params => params)
    @projects = JSON.parse(resp.body)

    group_tasks = []
    @projects.each do |p|
      if p["item_order"] > 2
        params[:project_id] = p["id"]
        resp = RestClient.get(url + "getUncompletedItems", :accept => :json, :params => params)
        group_tasks.concat(JSON.parse(resp.body))
      end
    end
    @tasks.push(group_tasks[rand(group_tasks.size)])  unless group_tasks.empty?

    params[:project_id] = @projects[0]["id"]
    resp = RestClient.get(url + "getUncompletedItems", :accept => :json, :params => params)
    arr = JSON.parse(resp.body)
    @tasks.push(arr[rand(arr.size)]) unless arr.empty?

    params[:project_id] = @projects[1]["id"]
    resp = RestClient.get(url + "getUncompletedItems", :accept => :json, :params => params)
    arr = JSON.parse(resp.body)
    @tasks.push(arr[rand(arr.size)]) unless arr.empty?

  end

end
