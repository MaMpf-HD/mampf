import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["results", "form"];

  connect() {
    this.loadAllLectures = this.loadAllLectures.bind(this);
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.loaded) {
            this.loadAllLectures();
            this.loaded = true;
          }
        });
      },
      {
        root: null,
        threshold: 0.1,
      },
    );

    this.observer.observe(this.element);
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  loadAllLectures() {
    const form = this.hasFormTarget ? this.formTarget : this.element.querySelector("form");

    if (!form) {
      return;
    }

    const formData = new FormData(form);
    const params = new URLSearchParams(formData);

    fetch(`${form.action}?${params}`, {
      method: "GET",
      headers: {
        "Accept": "text/javascript",
        "X-Requested-With": "XMLHttpRequest",
      },
    })
      .then(response => response.text())
      .then((script) => {
        eval(script);
      });
  }
}
