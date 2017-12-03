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
        field :video_thumbnail_link do
          help "Mandatory if 'Video stream link' or 'Video file link' are given."
        end
        field :manuscript_link
        field :external_reference_link do
          help "Optional. If Sort is 'KeksQuestion', this field will be filled automatically using the question_id."
        end
        field :tags
        field :linked_media
        field :heading do
          help "Optional. Used as heading in card body if Sort is 'KeksQuiz, 'Reste' or 'Kiwi'."
        end
        field :description do
          help "Overrides the generic description in card subheader. Used if Sort is 'Reste'."
        end
        field :question_id do
          help "Mandatory if sort is 'KeksQuestion'."
        end
        field :question_list do
          help "Mandatory if sort is 'KeksQuiz'. In this case, use format like: 15&371&22"
        end
        field :length do
          help "Mandatory if video file or stream is given. In this case, use format like: 1h26m12s"
        end
        field :video_size do
          help "Mandatory video file is given. In this case, use format like: 123 MiB"
        end
        field :width do
          help "Mandatory if video file or stream is given."
        end
        field :height do
          help "Mandatory if video file or stream is given."
        end
        field :embedded_width do
          help "Mandatory if video stream is given."
        end
        field :embedded_height do
          help "Mandatory if video stream is given."
        end
        field :pages do
          help "Mandatory if manuscript is given."
        end
        field :manuscript_size do
          help "Mandatory if manuscript is given."
        end
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
        field :id
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
        exclude_fields :media, :created_at, :updated_at
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
        field :id
        field :date
        field :lecture
        field :number
        field :sections
        field :tags
        field :media
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Section do
      list do
        field :id
        field :number
        field :title
        field :chapter
        field :number_alt
        field :lessons
      end
      edit do
        field :chapter
        field :number do
          help 'Required. Number of the section if linear numbering is used.'
        end
        field :title
        field :number_alt do
          help 'Optional. Use e.g. if sections are numbered within chapter, e.g. 5.2'
        end
        field :tags
        field :lessons
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Tag do
      list do
        field :id
        field :title
        field :courses
        field :related_tags
      end
      edit do
        field :title
        field :courses
        field :related_tags
        field :additional_lectures
        field :disabled_lectures
        field :sections
        fields :lessons
        field :media
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Teacher do
      list do
        field :id
        field :name
        field :email
        field :lectures
        field :homepage
      end
      edit do
        field :id
        field :name
        field :email
        field :lectures
        field :homepage
      end
    end
  end

  RailsAdmin.config do |config|
    config.model Term do
      list do
        field :id
        field :year
        field :season
        field :lectures
      end
    end
  end
end
