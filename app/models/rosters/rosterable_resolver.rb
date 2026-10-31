module Rosters
  # Centralizes the logic for resolving "rosterable" entities (Tutorials, Cohorts, Talks, Lectures)
  class RosterableResolver
    COLLECTION_MAP = {
      "Tutorial" => :tutorials,
      "Talk" => :talks,
      "Cohort" => :cohorts,
      "Lecture" => nil
    }.freeze

    def self.eager_load_lecture(id)
      Lecture.includes(
        { registration_campaigns: [:user_registrations, :registration_items,
                                   :registration_policies] },
        tutorials: [:tutors, :tutorial_memberships,
                    { registration_items: {
                      registration_campaign: :registration_policies
                    } }],
        cohorts: [:cohort_memberships,
                  { registration_items: {
                    registration_campaign: :registration_policies
                  } }],
        talks: [:speakers, :speaker_talk_joins,
                { registration_items: {
                  registration_campaign: :registration_policies
                } }]
      ).find_by(id: id)
    end

    def self.resolve(params, lecture: nil)
      type = params[:type]
      klass = Rosters::Rosterable.class_for(type)
      return nil unless klass

      param_key = "#{type.underscore}_id"
      id = params[param_key] || params[:id]
      rosterable = klass.find_by(id: id)
      return nil unless rosterable

      reload(rosterable, lecture: lecture)
    end

    def self.reload(rosterable, lecture:)
      return rosterable if rosterable.nil?
      return lecture if rosterable.is_a?(Lecture) && lecture
      return rosterable if lecture.nil? || rosterable.is_a?(Lecture)

      collection = collection_for(rosterable.class.name, lecture)
      return rosterable unless collection

      collection.find { |r| r.id == rosterable.id } || rosterable
    end

    def self.find_target(id, type:, lecture:, default_type:)
      target_type = type.presence || default_type
      klass = Rosters::Rosterable.class_for(target_type)
      return nil unless klass

      if klass == Cohort
        klass.find_by(id: id, context: lecture)
      else
        klass.find_by(id: id, lecture: lecture)
      end
    end

    # Names a group in a parameter or a data attribute, e.g. "Tutorial-12";
    # find_place reads it back.
    def self.group_key(group)
      "#{group.class.name}-#{group.id}"
    end

    # Finds the group a group_key names, if it belongs to the lecture and
    # enrolls in it. Returns nil for anything else.
    def self.find_place(key, lecture:)
      type, id = key.to_s.split("-", 2)
      return if type.blank? || type == "Lecture"

      group = find_target(id, type: type, lecture: lecture, default_type: nil)
      group if group&.enrolls_in_lecture?
    end

    def self.collection_for(type_name, lecture)
      assoc = COLLECTION_MAP[type_name]
      return nil unless assoc

      lecture.public_send(assoc)
    end
    private_class_method :collection_for
  end
end
