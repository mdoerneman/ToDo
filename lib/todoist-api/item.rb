module Todoist
  class Item < Todoist::Base
    attr_reader :id
    
    attr_accessor :project_id, :content, :priority, :item_order, :indent
    attr_accessor :in_history, :collapsed
    
    def initialize(data={})
      load_data(data) if data.kind_of?(Hash)
    end
    
    # Returns true if item is new
    def new?
      @id.nil?
    end
    
    # Returns JSON representation of item
    def to_json(opts=nil)
      {
        :id         => @id,
        :project_id => @id,
        :content    => @content,
        :priority   => @priority,
        :item_order => @item_order,
        :indent     => @indent,
        :in_history => @in_history,
        :collapsed  => @collapsed
      }.to_json
    end
    
    # Save or create item
    def save
      raise ArgumentError, 'Content required!' if @content.to_s.empty?
      raise ArgumentError, 'Project ID required!' if @project_id.nil?
    
      action = new? ? 'addItem' : 'updateItem'
      request(action, :project_id => @project_id, :content => @content)
    end
    
    # Delete item from the project
    def delete
      Item.delete([@id])
    end
    
    # Move item under another project
    # target_id => id of the project to move to
    def move_to(target_id)
      Item.move_to([@id], @project_id, target_id)
    end
    
    # Get one items by ID
    def self.get(project_id, id)
      get_by_ids(project_id, [id])
    end
    
    # Get multiple items by IDs
    def self.get_by_ids(project_id, ids=[])
      request('getItemsById', :ids => ids)
    end
    
    # Delete items by IDs
    # ids => array of item ids
    def self.delete(ids=[])
      return if ids.nil? || ids.empty?
      request('deleteItems', :ids => ids)
    end
    
    # Move items under another project
    # ids => array of item ids
    # project_from => project id to move from
    # project_to => project id to move to
    def self.move(ids, project_from, project_to)
      mapping = {}
      mapping[String(project_from)] = ids
      request('moveItems', :project_items => mapping, :to_project => project_to)
    end
    
    # Get all uncompleted items for project
    def self.uncompleted(project_id)
      items = request('getUncompletedItems', :project_id => project_id)
      items.map { |i| Item.new(i) }
    end
      
    # Get all completed items for project
    def self.completed(project_id)
      items = request('getCompletedItems', :project_id => project_id)
      items.map { |i| Item.new(i) }
    end
    
    protected
    
    def load_data(data={})
      data.symbolize_keys!
      @id = data.delete(:id) || nil
      data.each_pair do |k,v|
        self.send("#{k}=".to_sym, v) if self.respond_to?(k)
      end
    end
  end
end