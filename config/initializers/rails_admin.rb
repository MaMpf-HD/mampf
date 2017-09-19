RailsAdmin.config do |config|

  config.parent_controller = 'ApplicationController'
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
   config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.excluded_models = ['AssetMediumJoin', 'Connection', 'CourseTagJoin',
                            'LectureTagAdditionalJoin', 'LectureTagDisabledJoin',
                            'LectureUserJoin', 'LessonSectionJoin', 'LessonTagJoin',
                            'MediumTagJoin', 'SectionTagJoin']

  RailsAdmin.config {|c| c.label_methods << :to_label}

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  models = ['Asset', 'Chapter', 'Course', 'Lecture', 'Lesson', 'Medium',
            'Section', 'Tag', 'Relation', 'Teacher', 'Term']

  RailsAdmin.config do |config|
    models.each do |m|
      config.model m do
        list do
          exclude_fields :created_at, :updated_at
        end
      end
    end
  end
end
