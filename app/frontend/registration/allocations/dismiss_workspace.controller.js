import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.workspaceElement?.classList.add("is-active");
  }

  disconnect() {
    this.workspaceElement?.classList.remove("is-active");
  }

  clear() {
    this.workspaceElement?.classList.remove("is-active");
    this.element.remove();
  }

  get workspaceElement() {
    return this.element.parentElement;
  }
}
