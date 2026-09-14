import { Controller } from "@hotwired/stimulus";

const PAGE_SIZE_KEY = "pointing-table-page-size";

// Narrows the rows to a name, a state and a group, and cuts what is left
// into pages when the table asks for a page size. Rows come back one at a
// time after a save, so every new row is measured against the filters too.
// A sheet from before there were states offers no state filter.
export default class extends Controller {
  static targets = [
    "row", "name", "status", "tutorial", "reset", "count", "empty",
    "pager", "pageSize", "pageInfo", "previous", "next",
  ];

  static values = { pageSize: Number };

  initialize() {
    this.page = 1;
  }

  // The page size chosen once holds for every table on this browser; the
  // table's own value is the default for a first visit.
  connect() {
    if (!this.hasPageSizeTarget) {
      return;
    }
    const stored = Number(localStorage.getItem(PAGE_SIZE_KEY));
    if (stored > 0) {
      this.pageSizeValue = stored;
    }
    this.pageSizeTarget.value = this.pageSizeValue;
    this.render();
  }

  changePageSize() {
    this.pageSizeValue = Number(this.pageSizeTarget.value);
    localStorage.setItem(PAGE_SIZE_KEY, this.pageSizeValue);
    this.apply();
  }

  rowTargetConnected() {
    this.renderSoon();
  }

  rowTargetDisconnected() {
    this.renderSoon();
  }

  // A replaced row leaves and arrives in one mutation; rendering in between
  // would count one row fewer and could turn a page back. One render after
  // the batch also serves the initial connect of every row.
  renderSoon() {
    if (!this.hasNameTarget || this.renderQueued) {
      return;
    }
    this.renderQueued = true;
    queueMicrotask(() => {
      this.renderQueued = false;
      this.render();
    });
  }

  // A change of filter starts over on the first page.
  apply() {
    this.page = 1;
    this.render();
  }

  previousPage() {
    this.page -= 1;
    this.render();
  }

  nextPage() {
    this.page += 1;
    this.render();
  }

  render() {
    const matching = this.rowTargets.filter(row => this.matches(row));
    const pages = this.pageSizeValue > 0
      ? Math.max(1, Math.ceil(matching.length / this.pageSizeValue))
      : 1;
    this.page = Math.min(Math.max(this.page, 1), pages);
    const from = this.pageSizeValue > 0 ? (this.page - 1) * this.pageSizeValue : 0;
    const to = this.pageSizeValue > 0 ? from + this.pageSizeValue : matching.length;

    const onPage = new Set(matching.slice(from, to));
    this.rowTargets.forEach((row) => {
      row.hidden = !onPage.has(row);
    });

    this.report(matching.length);
    this.paginate(matching.length, from, to, pages);
  }

  search() {
    this.apply();
  }

  reset() {
    this.nameTarget.value = "";
    if (this.hasStatusTarget) {
      this.statusTarget.value = "all";
    }
    if (this.hasTutorialTarget) {
      this.tutorialTarget.value = "all";
    }
    this.apply();
  }

  // The state select also offers spots a row can be in beyond its state,
  // as "flag:<name>" options; a row lists its flags space-separated.
  matches(row) {
    const query = this.nameTarget.value.trim().toLowerCase();
    const status = this.hasStatusTarget ? this.statusTarget.value : "all";
    const tutorial = this.hasTutorialTarget ? this.tutorialTarget.value : "all";
    return (query === "" || row.dataset.statusFilterName.toLowerCase().includes(query))
      && this.matchesStatus(row, status)
      && (tutorial === "all" || (row.dataset.statusFilterTutorial || "none") === tutorial);
  }

  matchesStatus(row, status) {
    if (status === "all") {
      return true;
    }
    if (status.startsWith("flag:")) {
      return (row.dataset.statusFilterFlags || "").split(" ").includes(status.slice(5));
    }
    return row.dataset.statusFilterStatus === status;
  }

  showStatus({ params: { status } }) {
    this.statusTarget.value = status;
    this.apply();
  }

  report(shown) {
    const total = this.rowTargets.length;
    if (this.hasResetTarget) {
      this.resetTarget.hidden = !this.filtering();
    }
    if (this.hasCountTarget) {
      this.countTarget.hidden = !this.filtering();
      this.countTarget.textContent = this.countTarget.dataset.template
        .replace("%{shown}", shown)
        .replace("%{total}", total);
    }
    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = shown > 0;
    }
  }

  // Fewer rows than the smallest page need no pager at all.
  paginate(total, from, to, pages) {
    if (!this.hasPageSizeTarget) {
      return;
    }
    const hidden = total <= this.smallestPageSize();
    this.pagerTargets.forEach((pager) => {
      pager.hidden = hidden;
    });
    this.pageInfoTargets.forEach((info) => {
      info.textContent = info.dataset.template
        .replace("%{from}", total === 0 ? 0 : from + 1)
        .replace("%{to}", Math.min(to, total))
        .replace("%{total}", total);
    });
    this.previousTargets.forEach(button => this.enable(button, this.page > 1));
    this.nextTargets.forEach(button => this.enable(button, this.page < pages));
  }

  smallestPageSize() {
    const sizes = [...this.pageSizeTarget.options].map(option => Number(option.value));
    return Math.min(...sizes);
  }

  // Bootstrap greys a page link by class, not by the attribute that
  // actually stops the click.
  enable(button, enabled) {
    button.disabled = !enabled;
    button.classList.toggle("disabled", !enabled);
  }

  filtering() {
    return this.nameTarget.value.trim() !== ""
      || (this.hasStatusTarget && this.statusTarget.value !== "all")
      || (this.hasTutorialTarget && this.tutorialTarget.value !== "all");
  }
}
