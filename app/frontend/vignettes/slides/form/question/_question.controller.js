import { Controller } from "@hotwired/stimulus";

// https://stackoverflow.com/a/73701632/
// https://discuss.hotwired.dev/t/how-to-return-different-partial-with-hotwire-on-select-dropdwon-change/4571/6
export default class extends Controller {
  connect() {
    const questionForm = this.element.closest("form");
    this.frame = questionForm.querySelector("turbo-frame");
  }

  changeQuestionType(_event) {
    // const newType = event.target.value;
    console.log(this.frame);
    // const { url } = this.frame;
    // console.log("refreshing frame", url);
    // this.element.src = url;
  }
}
