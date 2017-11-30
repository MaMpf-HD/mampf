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

  config.excluded_models = ['CourseTagJoin', 'LectureTagAdditionalJoin',
                            'LectureTagDisabledJoin', 'LectureUserJoin',
                            'LessonSectionJoin', 'LessonTagJoin', 'Link',
                            'MediumTagJoin', 'Relation', 'SectionTagJoin',
                            'Connection']

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

  models = ['Section', 'Tag', 'Teacher', 'Term']

  RailsAdmin.config do |config|
    models.each do |m|
      config.model m do
        list do
          exclude_fields :created_at, :updated_at
        end
      end
    end
  end

  RailsAdmin.config do |config|
    config.model User do
      list do
        field :id
        field :email
        field :created_at
        field :sign_in_count do
          label 'Visits'
          column_width 80
        end
        field :current_sign_in_at
        field :lectures
        field :subscription_type do
          label 'Type'
        end
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Medium do
      list do
        field :id
        field :title
        field :sort
        field :teachable
        field :heading
        field :linked_media
      end
      edit do
        field :title
        field :author
        field :sort
        field :teachable
        field :video_stream_link
        field :video_file_link
        field :video_thumbnail_link
        field :manuscript_link
        field :external_reference_link
        field :tags
        field :linked_media
        field :heading
        field :description
        field :question_id
        field :question_list
        field :length
        field :video_size
        field :width
        field :height
        field :embedded_width
        field :embedded_height
        field :pages
        field :manuscript_size
        field :authoring_software
        field :video_player
        field :extras_link
        field :extras_description
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Chapter do
      list do
        field :title
        field :number
        field :lecture
        field :sections
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Course do
      list do
        exclude_fields :id, :media, :created_at, :updated_at
      end
      create do
        exclude_fields :media
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Lecture do
      list do
        field :term
        field :course
        field :teacher
        field :kaviar do
          column_width 50
          label 'Kav'
        end
        field :keks do
          column_width 50
          label 'Kek'
        end
        field :sesam do
          column_width 50
          label 'Ses'
        end
        field :kiwi do
          column_width 50
          label 'Kiw'
        end
        field :erdbeere do
          column_width 50
          label 'Erd'
        end
        field :reste do
          column_width 50
          label 'Res'
        end
      end
      edit do
        field :teacher
        field :course
        field :term
        field :kaviar
        field :sesam
        field :keks
        field :reste
        field :erdbeere
        field :kiwi
        field :twitter
        field :additional_tags
        field :disabled_tags
        field :preceding_lectures
        field :chapters
        field :lessons
        fields :media
      end
      create do
        exclude_fields :chapters, :lessons, :media
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Lesson do
      list do
        field :date
        field :lecture
        field :number
        field :sections
        field :tags
        field :media
      end
    end
  end



end
