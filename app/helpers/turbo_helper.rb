module TurboHelper
  # Conditionally renders a turbo frame tag if the request is a Turbo frame
  # request. If not, it captures the block content without wrapping it in a
  # turbo frame.
  #
  # This is necessary in a scenario where the following two points apply:
  # - A partial/view is rendered with the whole layout upon initial page load.
  #   In this case, it should not be wrapped in a turbo frame, as it is part of
  #   the full page content that is loaded.
  # - The same partial/view is rendered as response to a Turbo frame request.
  #   To save bandwidth, the controller does not render the whole layout,
  #   but only the content of the partial or view. In this case, the content
  #   should be wrapped in a turbo frame such that Turbo knows which part of
  #   the full page to replace.
  def turbo_frame_tag_if_turbo_request(id, &)
    if turbo_frame_request?
      turbo_frame_tag(id, &)
    else
      capture(&)
    end
  end
end
