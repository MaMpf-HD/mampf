import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "input", "podiumName", "podiumSpot", "saveButton"];
  static values = {
    emptyLabel: String,
    readonly: Boolean,
  };

  connect() {
    this.refresh();
  }

  choose(event) {
    if (this.readonlyValue) return;

    const button = event.currentTarget;
    this.assignRank(button.dataset.itemId, Number(button.dataset.rank));
    this.refresh();
  }

  assignRank(itemId, targetRank) {
    const preferences = this.preferences();
    const currentRank = this.rankForItem(itemId, preferences);
    if (currentRank === targetRank) return;

    const displacedItemId = preferences[targetRank];
    preferences[targetRank] = itemId;

    if (currentRank) {
      if (displacedItemId) {
        preferences[currentRank] = displacedItemId;
      }
      else {
        preferences[currentRank] = "";
      }
    }
    else if (displacedItemId) {
      const openRank = this.openRank(preferences);
      if (openRank) preferences[openRank] = displacedItemId;
    }

    this.applyPreferences(preferences);
  }

  preferences() {
    return Object.fromEntries(
      this.inputTargets
        .filter(input => input.value)
        .map(input => [Number(input.dataset.rank), input.value]),
    );
  }

  applyPreferences(preferences) {
    this.inputTargets.forEach((input) => {
      input.value = preferences[Number(input.dataset.rank)] || "";
    });
  }

  rankForItem(itemId, preferences) {
    const rank = Object.entries(preferences).find(entry => entry[1] === itemId);
    return rank ? Number(rank[0]) : null;
  }

  openRank(preferences) {
    return this.ranks().find(rank => !preferences[rank]);
  }

  refresh() {
    const preferences = this.preferences();

    this.buttonTargets.forEach((button) => {
      const selected = preferences[Number(button.dataset.rank)] === button.dataset.itemId;
      button.classList.toggle("btn-primary", selected);
      button.classList.toggle("btn-outline-primary", !selected);
      button.setAttribute("aria-pressed", selected.toString());
    });

    this.podiumNameTargets.forEach((podiumName) => {
      const rank = Number(podiumName.dataset.rank);
      const itemId = preferences[rank];
      podiumName.textContent = itemId ? this.titleForItem(itemId) : this.emptyLabelValue;
    });

    this.podiumSpotTargets.forEach((spot) => {
      spot.classList.toggle(
        "student-registration-podium-spot--filled",
        Boolean(preferences[Number(spot.dataset.rank)]),
      );
    });

    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = this.readonlyValue || !this.complete(preferences);
    }
  }

  titleForItem(itemId) {
    return this.buttonTargets.find(button => button.dataset.itemId === itemId)
      ?.dataset.itemTitle || this.emptyLabelValue;
  }

  complete(preferences) {
    return this.ranks().every(rank => preferences[rank]);
  }

  ranks() {
    return this.inputTargets.map(input => Number(input.dataset.rank));
  }
}
