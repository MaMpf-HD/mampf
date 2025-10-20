import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  addOption(_event) {
    const template = $("#vignette-multiple-choice-options-template");
    const newOptionHtml = template.html();
    const uniqueId = new Date().getTime();
    const newBlockHtml = newOptionHtml.replace(/NEW_RECORD/g, uniqueId);
    $("#vignette-multiple-choice-options").append(newBlockHtml);
  }

  removeOption(event) {
    const parentDiv = $(event.target).closest("div");
    parentDiv.find("input").removeAttr("required");
    parentDiv.find(".vignette-mc-hidden-destroy").val("1");
    parentDiv.removeClass("d-flex").hide();
  }
}
