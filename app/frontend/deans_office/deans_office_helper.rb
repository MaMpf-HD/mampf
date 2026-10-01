# Explains registration terms for dean's office readers unfamiliar with how
# MaMpf hands out places.
module DeansOfficeHelper
  # Opens on click or keyboard focus; a link with a tabindex, since Safari
  # does not focus a button it is clicked on and the popover would not open.
  def deans_office_help(topic, content, html: false)
    tag.a(tabindex: 0, role: "button",
          class: "ms-1 text-secondary",
          title: topic,
          "aria-label": t("deans_office.help.about", topic: topic),
          data: { controller: "bs-popover", bs_toggle: "popover", bs_trigger: "focus",
                  bs_content: content, bs_html: html }) do
      tag.i(class: "bi bi-question-circle", "aria-hidden": true)
    end
  end

  def deans_office_phases_help
    tag.ul(class: "list-unstyled mb-0") do
      safe_join(DeansOffice::TermOverview::PHASE_ORDER.map do |phase|
        tag.li(class: "mb-1") do
          safe_join([tag.strong(t("deans_office.phases.#{phase}")),
                     t("deans_office.help.phases.#{phase}")], ": ")
        end
      end)
    end.to_str
  end
end
