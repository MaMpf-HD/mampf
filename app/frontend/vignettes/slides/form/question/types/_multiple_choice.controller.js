import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  addOption() {
    const template = this.element.querySelector("#vignette-multiple-choice-options-template");
    const newOptionHtml = template.innerHTML;
    const uniqueId = new Date().getTime();
    const newBlockHtml = newOptionHtml.replace(/NEW_RECORD/g, uniqueId);
    this.element.querySelector("#vignette-multiple-choice-options").innerHTML += newBlockHtml;
  }

  removeOption(event) {
    const parentDiv = $(event.target).closest("div");
    parentDiv.find("input").removeAttr("required");
    parentDiv.find(".vignette-mc-hidden-destroy").val("1");
    parentDiv.removeClass("d-flex").hide();
  }
}
