module Todoist
  class Project < Todoist::Base
    attr_reader :id
    attr_accessor :name, :color, :item_order, :indent
      
    def initialize(data={})
      load_data(data) if data.kind_of?(Hash)
    end
    
    # Returns a hash representation of project
    def to_hash
      {
        :id         => @id,
        :name       => @name,
        :indent     => @indent,
        :color      => @color,
        :item_order => @item_order
      }
    end
    
    # Return json representation
    def to_json(opts={})
      self.to_hash.to_json
    end
    
    # Returns string representation of project
    def to_s
      "#{@id} - #{@name}"
    end
    
    # Returns true if project is new
    def new?
      @id.nil?
    end
    
    # Save project settings
    def save
      raise Exception, 'Name required' if @name.to_s.empty?
      opts = self.to_hash ; opts.delete(:id)
      opts[:project_id] = @id unless new?
      action = new? ? 'addProject' : 'updateProject'
      load_data(request(action, opts))
    end
    
    # Delete this project
    def delete
      raise Exception, "Project does not exist yet!" if new?
      request('deleteProject', :project_id => id) == true
    end
    
    # Reload project information
    def reload!
      load_data(request('getProject', :project_id => id))
    end
    
    # Returns project's completed items
    def completed_items
      new? ? Array.new : Item.completed(@id)
    end
    
    # Returns project's uncompleted items
    def uncompleted_items
      new? ? Array.new : Item.uncompleted(@id)
    end
    
    # Initialize a new item for project
    def new_item(content)
      Item.new(:project_id => @project_id, :content => content)
    end
    
    # Fetch all projectes
    def self.all
      request('getProjects').map { |p| Project.new(p) }
    end
    
    # Fetch project by ID
    def self.get(id)
      Project.new(request('getProject', :project_id => id))
    end
    
    # Delete project by ID
    # NOTE: delete action always return success for some reason
    def self.delete(id)
      request('deleteProject', :project_id => id) == true
    end
    
    protected
    
    # Load hash data into the object
    def load_data(data)
      data.symbolize_keys!

      @id         = data[:id] || nil
      @name       = data[:name]
      @color      = data[:color]
      @indent     = data[:indent]
      @item_order = data[:item_order]
    end
  end
end