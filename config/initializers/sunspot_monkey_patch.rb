Sunspot::Rails::Searchable::ActsAsMethods.module_eval do
  def searchable(options = {}, &block)
    Sunspot.setup(self, &block)

    if searchable?
      sunspot_options[:include].concat(Sunspot::Util::Array(options[:include]))
    else
      extend Sunspot::Rails::Searchable::ClassMethods
      include  Sunspot::Rails::Searchable::InstanceMethods

      class_attribute :sunspot_options

      unless options[:auto_index] == false
        before_save :mark_for_auto_indexing_or_removal

        __send__ Sunspot::Rails.configuration.auto_index_callback,
                 :perform_index_tasks,
                 :if => :persisted?
      end

      unless options[:auto_remove] == false
        if ::Rails::VERSION::MAJOR >= 6
          __send__ Sunspot::Rails.configuration.auto_remove_callback,
                   proc { |searchable| searchable.remove_from_index },
                   :if => :destroy
        else
          __send__ Sunspot::Rails.configuration.auto_remove_callback,
                   proc { |searchable| searchable.remove_from_index },
                   :on => :destroy
        end
      end
      options[:include] = Sunspot::Util::Array(options[:include])

      self.sunspot_options = options
    end
  end
end