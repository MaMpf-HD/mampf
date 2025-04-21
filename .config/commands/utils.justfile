[private]
help:
    @just --list --justfile {{source_file()}}

# Generates entity-relationship diagrams (ERD) of the database
erd:
    #!/usr/bin/env bash

    # Make sure the mampf dev container is running
    cd {{justfile_directory()}}/docker/development/
    if [ -z "$(docker compose ps --services --filter 'status=running' | grep mampf)" ]; then
        echo "The mampf dev container is not running. Please start it first (use 'just docker')."
        exit 1
    fi

    mkdir -p {{justfile_directory()}}/tmp/erd/

    # ▶ Generate ERDs
    # Customize it with options from here: https://voormedia.github.io/rails-erd/customise.html
    # Also see the output from: 'bundle exec erd --help' (inside the dev container)

    # Ignore some tables
    ignored_thredded="Thredded::Post,Thredded::UserPostNotification,Thredded::PrivateUser,Thredded::UserPrivateTopicReadState,Thredded::PrivateTopic,Thredded::MessageboardUser,Thredded::PrivatePost,Thredded:UserDetail,Thredded::MessageboardGroup,Thredded::Messageboard,Thredded::Category,Thredded::TopicCategory,Thredded::Topic,Thredded::UserTopicReadState,Thredded::UserTopicFollow,Thredded::NotificationsForFollowedTopics,Thredded::MessageboardNotificationsForFollowedTopics,Thredded::UserPreference,Thredded::UserMessageboardPreference,Thredded::NotificationsForPrivateTopics,Thredded::PostModerationRecord,Thredded::UserDetail"
    ignored_translation="Mobility::Backends::ActiveRecord::Table::Translation,Subject::Translation,Program::Translation,Division::Translation"
    ignored_commontator="Commontable,Votable,Subscriber,Creator"
    other_ignored="ActionMailbox::Record,ActionText::Record,ActiveStorage::Record,Sluggable,FriendlyId::Slug,ApplicationRecord,InteractionsRecord"
    exclude_default="${ignored_thredded},${ignored_translation},${ignored_commontator},${other_ignored}"

    # 🌟 Overview with attributes (warnings will be printed only here)
    docker compose exec -it mampf rake erd \
        title=false filename=/usr/src/app/tmp/erd/mampf-erd-overview-with-attributes \
        inheritance=false polymorphism=true indirect=false attributes=content \
        exclude="${exclude_default}"

    # 🌟 Generic Overview
    docker compose exec -it mampf rake erd warn=false \
        title=false filename=/usr/src/app/tmp/erd/mampf-erd-overview \
        inheritance=false polymorphism=true indirect=false attributes=false \
        exclude="${exclude_default}"

    # 🌟 Vouchers
    docker compose exec -it mampf rake erd warn=false \
        title="Vouchers" filename=/usr/src/app/tmp/erd/mampf-erd-vouchers \
        inheritance=true polymorphism=true indirect=true attributes=content \
        exclude="${exclude_default},Teachable,Editable" \
        only="User,Claim,Voucher,Redemption,Lecture,Tutorial,Talk"

    # 🌟 Tutorials
    docker compose exec -it mampf rake erd warn=false \
        title="Tutorials" filename=/usr/src/app/tmp/erd/mampf-erd-tutorials \
        inheritance=true polymorphism=true indirect=true attributes=content \
        exclude="${exclude_default},Claimable,Editable,Teachable" \
        only="User,Lecture,Tutorial,Submission,Assignment,TutorTutorialJoin,UserSubmissionJoin"

    # 🌟 Courses
    docker compose exec -it mampf rake erd warn=false \
        title="Courses" filename=/usr/src/app/tmp/erd/mampf-erd-courses \
        inheritance=true polymorphism=true indirect=true attributes=content \
        exclude="${exclude_default},Claimable,Editable" \
        only="Subject,Program,Division,DivisionCourseJoin,Course,Lecture,CourseSelfJoin,Lesson"

    # 🌟 Lectures
    docker compose exec -it mampf rake erd warn=false \
        title="Lectures" filename=/usr/src/app/tmp/erd/mampf-erd-lectures \
        inheritance=true polymorphism=true indirect=true attributes=content \
        exclude="${exclude_default},Claimable,Editable,Teachable" \
        only="Lecture,Lesson,Chapter,Section,Item,LessonSectionJoin,Term"

    # 🌟 Vignettes
    docker compose exec -it mampf rake erd warn=false \
        title="Vignettes" filename=/usr/src/app/tmp/erd/mampf-erd-vignettes \
        inheritance=true polymorphism=true indirect=true attributes=content \
        exclude="${exclude_default},Claimable,Editable,Teachable,Notifiable,Record" \
        only="Vignettes::Questionnaire, Vignettes::Slide, Vignettes::InfoSlide, Vignettes::Answer, Vignettes::UserAnswer, Vignettes::Question, Vignettes::SlideStatistic, Vignettes::LikertScaleAnswer, Vignettes::LikertScaleQuestion, Vignettes::MultipleChoiceAnswer, Vignettes::MultipleChoiceQuestion, Vignettes::TextQuestion, Vignettes::TextAnswer, Vignettes::LikertScaleAnswer, Vignettes::LikertScaleQuestion, Vignettes::MultipleChoiceAnswer, Vignettes::MultipleChoiceQuestion, Vignettes::TextAnswer, Vignettes::Option, Vignettes::Codename, Vignettes::CompletionMessage, Lecture"

    echo "📂 Diagrams are ready for you in the folder {{justfile_directory()}}/tmp/erd/"
    echo "🔀 For the meanings of the arrows, refer to https://voormedia.github.io/rails-erd/gallery.html#notations"
