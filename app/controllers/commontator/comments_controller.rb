# The CommmentsController is copied from the Commontator gem
# Only minor customizations are made
module Commontator
  class CommentsController < Commontator::ApplicationController
    before_action :set_thread, only: [:new, :create]
    before_action :set_comment_and_thread, except: [:new, :create]
    before_action :commontator_set_thread_variables,
                  only: [:show, :update, :delete, :undelete]

    # GET /comments/1
    def show
      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js
      end
    end

    # GET /threads/1/comments/new
    def new
      @comment = Commontator::Comment.new(thread: @commontator_thread,
                                          creator: @commontator_user)
      parent_id = params.dig(:comment, :parent_id)
      if parent_id.present?
        parent = Commontator::Comment.find(parent_id)
        @comment.parent = parent
        if [:q,
            :b].include?(@commontator_thread.config.comment_reply_style)
          @comment.body = "<blockquote><span class=\"author\">#{
            Commontator.commontator_name(parent.creator)
          }</span>\n#{
            parent.body
          }\n</blockquote>\n"
        end
      end
      security_transgression_unless(@comment.can_be_created_by?(@commontator_user))

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js
      end
    end

    # GET /comments/1/edit
    def edit
      @comment.editor = @commontator_user
      security_transgression_unless(@comment.can_be_edited_by?(@commontator_user))

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js
      end
    end

    # POST /threads/1/comments
    def create
      @comment = Commontator::Comment.new(
        thread: @commontator_thread, creator: @commontator_user, body: params.dig(
          :comment, :body
        )
      )
      parent_id = params.dig(:comment, :parent_id)
      @comment.parent = Commontator::Comment.find(parent_id) if parent_id.present?
      security_transgression_unless(@comment.can_be_created_by?(@commontator_user))

      respond_to do |format|
        if params[:cancel].blank?
          if @comment.save
            sub = @commontator_thread.config.thread_subscription.to_sym
            @commontator_thread.subscribe(@commontator_user) if [:a, :b].include?(sub)
            subscribe_mentioned if @commontator_thread.config.mentions_enabled
            Commontator::Subscription.comment_created(@comment)
            # The next line constitutes a customization of the original controller
            update_unread_status
            activate_unread_comments_icon_if_necessary

            @commontator_page = @commontator_thread.new_comment_page(
              @comment.parent_id, @commontator_show_all
            )

            format.js
          else
            format.js { render :new }
          end
        else
          format.js { render :cancel }
        end

        format.html { redirect_to commontable_url }
      end
    end

    # PUT /comments/1
    def update
      @comment.editor = @commontator_user
      @comment.body = params.dig(:comment, :body)
      security_transgression_unless(@comment.can_be_edited_by?(@commontator_user))

      respond_to do |format|
        if params[:cancel].blank?
          if @comment.save
            subscribe_mentioned if @commontator_thread.config.mentions_enabled

            format.js
          else
            format.js { render :edit }
          end
        else
          @comment.restore_attributes

          format.js { render :cancel }
        end

        format.html { redirect_to commontable_url }
      end
    end

    # PUT /comments/1/delete
    def delete
      security_transgression_unless(@comment.can_be_deleted_by?(@commontator_user))

      unless @comment.delete_by(@commontator_user)
        @comment.errors.add(:base,
                            t("commontator.comment.errors.already_deleted"))
      end

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js { render :delete }
      end
    end

    # PUT /comments/1/undelete
    def undelete
      security_transgression_unless(@comment.can_be_deleted_by?(@commontator_user))

      @comment.errors.add(:base, t("commontator.comment.errors.not_deleted")) \
        unless @comment.undelete_by(@commontator_user)

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js { render :delete }
      end
    end

    # PUT /comments/1/upvote
    def upvote
      security_transgression_unless(@comment.can_be_voted_on_by?(@commontator_user))

      @comment.upvote_from(@commontator_user)

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js { render :vote }
      end
    end

    # PUT /comments/1/downvote
    def downvote
      security_transgression_unless(@comment.can_be_voted_on_by?(@commontator_user) && \
                                    @comment.thread.config.comment_voting.to_sym == :ld)

      @comment.downvote_from(@commontator_user)

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js { render :vote }
      end
    end

    # PUT /comments/1/unvote
    def unvote
      security_transgression_unless(@comment.can_be_voted_on_by?(@commontator_user))

      @comment.unvote(voter: @commontator_user)

      respond_to do |format|
        format.html { redirect_to commontable_url }
        format.js { render :vote }
      end
    end

    protected

      def set_comment_and_thread
        @comment = Commontator::Comment.find(params[:id])
        @commontator_thread = @comment.thread
      end

      def subscribe_mentioned
        Commontator.commontator_mentions(@commontator_user, @commontator_thread,
                                         "")
                   .where(id: params[:mentioned_ids])
                   .find_each do |user|
          @commontator_thread.subscribe(user)
        end
      end

      # Updates the unread_comments flag for users subscribed to the current thread.
      # This method should only be called when a new comment was created.
      #
      # The originator of the comment does not get the flag set since that user
      # already knows about the comment; that user has just created it after all.
      #
      # (This is a customization of the original controller provided
      # by the commontator gem.)
      def update_unread_status
        medium = @commontator_thread.commontable
        return unless medium.released.in?(["all", "users", "subscribers"])

        relevant_users = medium.teachable.media_scope.users
        relevant_users.where.not(id: current_user.id)
                      .where(unread_comments: false)
                      .update(unread_comments: true)
      end

      # Might activate the flag used in the view to indicate unread comments.
      # This method should only be called when a new comment was created.
      # The flag is activated if the current user has not seen all comments
      # in the thread in which the new comment was created.
      #
      # The flag might only be activated, not deactivated since the checks
      # performed here are not sufficient to determine whether a user has
      # any unread comments (including those in possibly other threads).
      #
      # This method was introduced for one specific edge case:
      # When the current user A has just created a new comment in a thread,
      # but in the meantime, another user B has created a comment in the same
      # thread. User A will not be informed immediately about the new comment
      # by B since we don't have websockets implemented. Instead, A will be
      # informed by a visual indicator as soon as A has posted their own comment.
      #
      # (This is a customization of the original controller provided
      # by the commontator gem.)
      def activate_unread_comments_icon_if_necessary
        reader = Reader.find_by(user: current_user, thread: @commontator_thread)
        @update_icon = true if unseen_comments_in_current_thread?(reader)
      end

      def unseen_comments_in_current_thread?(reader = nil)
        @commontator_thread.comments.any? do |c|
          not_marked_as_read_in_reader = reader.nil? || c.created_at > reader.updated_at
          c.creator != current_user && not_marked_as_read_in_reader
        end
      end
  end
end
