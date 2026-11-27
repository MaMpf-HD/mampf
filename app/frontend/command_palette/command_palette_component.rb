class CommandPaletteComponent < ViewComponent::Base
  GROUPS = [:favorites, :recent, :lectures, :lecture_pages, :go_to, :actions].freeze

  def initialize(user:, lecture: nil)
    super()
    @user = user
    @lecture = lecture
  end

  def controller_data
    data = {
      controller: "command-palette",
      command_palette_me_url_value: command_palette_me_path(version: me_version),
      command_palette_catalog_url_value: command_palette_catalog_path,
      command_palette_user_id_value: @user.id,
      command_palette_group_labels_value: group_labels.to_json
    }
    return data unless lecture_visible?

    data.merge(
      command_palette_lecture_id_value: @lecture.id,
      command_palette_pinned_value: pinned?,
      command_palette_pin_action_value: pin_action("pin", pin_lecture_path).to_json,
      command_palette_unpin_action_value: pin_action("unpin", unpin_lecture_path).to_json
    )
  end

  private

    # The browser keeps the user's data across Turbo visits, keyed by this URL.
    # Another user, locale or pin (which touches the user) needs fresh data.
    def me_version
      "#{@user.id}-#{I18n.locale}-#{@user.updated_at.to_i}"
    end

    # The ResultGroup names of types.ts mapped to their headings.
    def group_labels
      GROUPS.to_h do |group|
        [group.to_s.camelize(:lower), t("command_palette.groups.#{group}")]
      end
    end

    # Whether the user may see (and thus pin) the open lecture, as in
    # ProfileController#lecture_visible_to_user?.
    def lecture_visible?
      @lecture.present? && (@lecture.published? || @user.admin? ||
                            @lecture.edited_by?(@user))
    end

    def pinned?
      @user.favorite_lectures.exists?(@lecture.id)
    end

    def pin_action(key, path)
      title = @lecture.course.short_title
      keywords = I18n.available_locales.flat_map do |locale|
        I18n.t("command_palette.#{key}_keywords", locale: locale)
      end
      { key: key, icon: key == "pin" ? "bi-pin-angle" : "bi-pin-angle-fill",
        label: t("command_palette.#{key}", title: title),
        keywords: keywords.uniq,
        path: "#{path}?#{{ lecture: { id: @lecture.id } }.to_query}",
        method: "patch" }
    end
end
