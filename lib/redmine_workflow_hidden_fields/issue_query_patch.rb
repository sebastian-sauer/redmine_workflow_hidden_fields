module RedmineWorkflowHiddenFields
  module  IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        #alias_method_chain :initialize_available_filters, :hidden
        alias_method_chain :available_columns, :hidden
        alias_method_chain :available_filters, :hidden
      end
    end

    module InstanceMethods

      def available_columns_with_hidden
	if @permissions_cache == nil
		logger.debug("Permissions cache is nil")
		@permissions_cache = Hash.new
	end

	@available_columns = available_columns_without_hidden
	logger.debug("Get available columns with hidden for project: " + project.to_s)
	start = Time.now
        if project == nil
          hidden_fields = []
          all_projects.each { |prj| 
            if prj.visible? and User.current.roles_for_project(prj).count > 0
              hidden_fields = hidden_fields == [] ? prj.completely_hidden_attribute_names : hidden_fields & prj.completely_hidden_attribute_names
            end
          }
        else
	  identifier = project.to_s + "--///--" + User.current.to_s
	  if @permissions_cache[identifier] != nil
		logger.debug("Read hidden fields from permissions cache")
		hidden_fields = @permissions_cache[identifier]
	  else 
        	logger.debug("Read new fields and save them to permissions cache later on.")  
		hidden_fields = project.completely_hidden_attribute_names
        	@permissions_cache[identifier] = hidden_fields
	  end
	end
        hidden_fields.map! {|field| field.sub(/_id$/, '')}  

          @available_columns.reject! {|column|
            hidden_fields.include?(column.name.to_s)
          } 
	finish = Time.now
	logger.debug("get available columns with hidden took: " + (finish - start).to_s)
        @available_columns
      end

        def available_filters_with_hidden
          @available_filters = available_filters_without_hidden
          hidden_fields.each {|field|
            delete_available_filter field
            if field == "assigned_to_id" then
              delete_available_filter "assigned_to_role"
            end
            if field == "assigned_to_id" then
              delete_available_filter "member_of_group"
            end
          }
          @available_filters
        end

    end
  end
end
