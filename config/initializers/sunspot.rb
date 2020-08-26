# this is necessary in order to prevent solr from creating
# duplicate entries for Question, Quiz, Remark < Medium
# see https://stackoverflow.com/questions/14832938/rails-sunspot-solr-duplicate-indexing-on-inherited-classes
class StiInstanceAdapter < Sunspot::Adapters::InstanceAdapter

  def id
    @instance.id
  end

  def index_id
    return Sunspot::Adapters::InstanceAdapter.index_id_for(@instance.class.base_class.name, id)
  end

end

Sunspot::Adapters::InstanceAdapter.register(StiInstanceAdapter, Medium)