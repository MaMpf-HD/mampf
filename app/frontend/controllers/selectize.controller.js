import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (window.fillOptionsByAjax) {
      window.fillOptionsByAjax($(this.element));
    }
  }
}
