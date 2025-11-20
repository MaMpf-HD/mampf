module Registration
  class CampaignablePORO
    attr_accessor :id, :title

    def initialize(id:, title:)
      @id = id
      @title = title
    end
  end
end
