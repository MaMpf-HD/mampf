# The CommmentsController is copied from the Commontator gem
# Only minor customizations are made
class Commontator::CommentsController < Commontator::ApplicationController
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
      parent = Commontator::Comment.find parent_id
      @comment.parent = parent
      if [:q,
          :b].include? @commontator_thread.config.comment_reply_style
        @comment.body = "<blockquote><span class=\"author\">#{
            Commontator.commontator_name(parent.creator)
          }</span>\n#{
            parent.body
          }\n</blockquote>\n"
      end
    end
    security_transgression_unless @comment.can_be_created_by?(@commontator_user)

    respond_to do |format|
      format.html { redirect_to commontable_url }
      format.js
    end
  end

  # GET /comments/1/edit
  def edit
    @comment.editor = @commontator_user
    security_transgression_unless @comment.can_be_edited_by?(@commontator_user)

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
    security_transgression_unless @comment.can_be_created_by?(@commontator_user)

    respond_to do |format|
      if params[:cancel].blank?
        if @comment.save
          sub = @commontator_thread.config.thread_subscription.to_sym
          @commontator_thread.subscribe(@commontator_user) if [:a, :b].include?(sub)
          subscribe_mentioned if @commontator_thread.config.mentions_enabled
          Commontator::Subscription.comment_created(@comment)
          # The next line constitutes a customization of the original controller
          update_unread_status

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
    security_transgression_unless @comment.can_be_edited_by?(@commontator_user)

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
    security_transgression_unless @comment.can_be_deleted_by?(@commontator_user)

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
    security_transgression_unless @comment.can_be_deleted_by?(@commontator_user)

    @comment.errors.add(:base, t("commontator.comment.errors.not_deleted")) \
      unless @comment.undelete_by(@commontator_user)

    respond_to do |format|
      format.html { redirect_to commontable_url }
      format.js { render :delete }
    end
  end

  # PUT /comments/1/upvote
  def upvote
    security_transgression_unless @comment.can_be_voted_on_by?(@commontator_user)

    @comment.upvote_from @commontator_user

    respond_to do |format|
      format.html { redirect_to commontable_url }
      format.js { render :vote }
    end
  end

  # PUT /comments/1/downvote
  def downvote
    security_transgression_unless @comment.can_be_voted_on_by?(@commontator_user) && \
                                  @comment.thread.config.comment_voting.to_sym == :ld

    @comment.downvote_from @commontator_user

    respond_to do |format|
      format.html { redirect_to commontable_url }
      format.js { render :vote }
    end
  end

  # PUT /comments/1/unvote
  def unvote
    security_transgression_unless @comment.can_be_voted_on_by?(@commontator_user)

    @comment.unvote voter: @commontator_user

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
                 .each do |user|
        @commontator_thread.subscribe(user)
      end
    end

    # This method ensures that the unread_comments flag is updated
    # for users affected by the creation of a newly created comment
    # It constitues a customization
    def update_unread_status
      medium = @commontator_thread.commontable
      return unless medium.released.in?(["all", "users", "subscribers"])

      relevant_users = medium.teachable.media_scope.users
      relevant_users.where.not(id: current_user.id)
                    .where(unread_comments: false)
                    .update_all(unread_comments: true) # rubocop:todo Rails/SkipsModelValidations

      # make sure that the thread associated to this comment is marked as read
      # by the comment creator (unless some other user posted a comment in it
      # that has not yet been read)
      @reader = Reader.find_or_create_by(user: current_user,
                                         thread: @commontator_thread)
      if unseen_comments?
        @update_icon = true
        return
      end
      @reader.update(updated_at: Time.current)
    end

    def unseen_comments?
      @commontator_thread.comments.any? do |c|
        c.creator != current_user && c.created_at > @reader.updated_at
      end
    end
end
