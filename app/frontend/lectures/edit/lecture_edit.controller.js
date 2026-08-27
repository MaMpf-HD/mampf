import { Controller } from "@hotwired/stimulus";

const COLLAPSE_TOGGLES = '[data-bs-toggle="collapse"]';

// While a tab has unsaved changes, the rest of the page is frozen: no editing
// somewhere else, no new items, no folding things open, until it is saved or
// discarded.
export default class extends Controller {
  static targets = ["contentCard", "importTags", "mediaCard", "showMediaButton",
    "startSection", "teamSize", "gracePeriod"];

  markUnsaved({ params: { warning, keepEditing } }) {
    this.reveal(document.getElementById(warning));

    document.querySelectorAll(".fa-edit").forEach((icon) => {
      if (keepEditing && icon.matches(keepEditing)) return;

      this.hide(icon);
    });
    document.querySelectorAll(".new-in-lecture").forEach(item => this.hide(item));
    document.querySelectorAll(COLLAPSE_TOGGLES).forEach((toggle) => {
      toggle.disabled = true;
      toggle.classList.remove("clickable");
    });
  }

  reload() {
    location.reload();
  }

  // The assignment fields hold their saved value, so this tab can put itself
  // back instead of reloading.
  restoreAssignments({ params: { warning } }) {
    this.hide(document.getElementById(warning));
    document.querySelectorAll(COLLAPSE_TOGGLES).forEach((toggle) => {
      toggle.disabled = false;
      toggle.classList.add("clickable");
    });
    document.querySelectorAll(".new-in-lecture").forEach(item => this.show(item));

    if (this.hasTeamSizeTarget) {
      this.teamSizeTarget.value = this.teamSizeTarget.dataset.value;
    }
    if (this.hasGracePeriodTarget) {
      this.gracePeriodTarget.value = this.gracePeriodTarget.dataset.value;
    }
  }

  confirmForumDeletion(event) {
    if (confirm(event.params.confirmation)) return;

    event.preventDefault();
  }

  toggleStartSection(event) {
    if (!this.hasStartSectionTarget) return;

    this.startSectionTarget.disabled = !event.target.checked;
  }

  // Tags hang off sections, so they cannot be imported on their own.
  toggleImportTags(event) {
    if (!this.hasImportTagsTarget) return;

    this.importTagsTarget.disabled = !event.target.checked;
    if (!event.target.checked) this.importTagsTarget.checked = false;
  }

  hideMedia() {
    this.hide(this.mediaCardTarget);
    this.contentCardTarget.classList.remove("col-xxl-9");
    this.reveal(this.showMediaButtonTarget);
  }

  showMedia() {
    this.contentCardTarget.classList.add("col-xxl-9");
    this.show(this.mediaCardTarget);
    this.hide(this.showMediaButtonTarget);
  }

  // What a stylesheet hides needs an inline display to come back; what this
  // controller hid only needs its inline display taken away again.
  reveal(element) {
    if (element) element.style.display = "block";
  }

  show(element) {
    if (element) element.style.display = "";
  }

  hide(element) {
    if (element) element.style.display = "none";
  }
}
