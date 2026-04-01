import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = ["studentList", "choiceDialog"];

  static values = {
    sourceType: String,
    sourceId: String,
    movePath: String,
    overbookingWarning: String,
  };

  sortableInstance = null;
  tileDropInstances = [];
  pendingDrop = null;
  highlightedTile = null;

  connect() {
    this.initDraggable();
    this.initDropZones();
  }

  disconnect() {
    this.sortableInstance?.destroy();
    this.tileDropInstances.forEach(s => s.destroy());
    this.tileDropInstances = [];
    this.clearHighlight();
  }

  initDraggable() {
    if (!this.hasStudentListTarget) return;

    this.sortableInstance = new Sortable(this.studentListTarget, {
      group: { name: "roster-students", pull: "clone", put: false },
      sort: false,
      draggable: ".tutorial-roster-student[data-user-id]",
      ghostClass: "roster-drag-ghost",
      chosenClass: "roster-drag-chosen",
      filter: ".tutorial-roster-student-remove, form, button, a",
      preventOnFilter: false,
      onMove: evt => this.updateHighlight(evt.to),
      onEnd: (evt) => {
        this.clearHighlight();
        if (evt.item.parentNode !== this.studentListTarget) {
          evt.item.remove();
        }
      },
    });
  }

  initDropZones() {
    this.tileDropInstances.forEach(s => s.destroy());
    this.tileDropInstances = [];

    const tiles = document.querySelectorAll(
      ".tutorial-gtile[data-roster-type][data-roster-id]",
    );

    tiles.forEach((tile) => {
      if (
        tile.dataset.rosterType === this.sourceTypeValue
        && tile.dataset.rosterId === String(this.sourceIdValue)
      ) {
        return;
      }

      const dropZone
        = tile.querySelector(".card-body") || tile;

      const instance = new Sortable(dropZone, {
        group: { name: "roster-drop", put: ["roster-students"] },
        draggable: ".roster-drag-phantom",
        ghostClass: "d-none",
        onAdd: (evt) => {
          evt.item.remove();
          this.handleDrop(tile, evt);
        },
      });

      this.tileDropInstances.push(instance);
    });
  }

  updateHighlight(dropZone) {
    const tile = dropZone.closest(".tutorial-gtile");
    if (tile === this.highlightedTile) return;

    this.clearHighlight();
    if (tile) {
      tile.classList.add("tutorial-gtile--drop-target");
      this.highlightedTile = tile;
    }
  }

  clearHighlight() {
    if (this.highlightedTile) {
      this.highlightedTile.classList.remove("tutorial-gtile--drop-target");
      this.highlightedTile = null;
    }
  }

  handleDrop(tile, evt) {
    const userId = evt.item?.dataset?.userId;
    if (!userId) return;

    const targetType = tile.dataset.rosterType;
    const targetId = tile.dataset.rosterId;
    const targetFull = tile.dataset.rosterFull === "true";
    const targetTitle = tile.dataset.rosterTitle;

    if (this.sourceTypeValue === "unassigned") {
      if (targetFull && !confirm(this.overbookingWarningValue)) {
        return;
      }
      this.submitAdd(userId, targetId, targetType);
      return;
    }

    const isCohortTarget = targetType === "cohort";

    if (isCohortTarget) {
      this.showChoiceDialog(userId, targetId, targetType, targetFull, targetTitle);
    }
    else {
      if (targetFull) {
        if (!confirm(this.overbookingWarningValue)) return;
      }
      this.submitMove(userId, targetId, targetType);
    }
  }

  showChoiceDialog(userId, targetId, targetType, targetFull, targetTitle) {
    if (!this.hasChoiceDialogTarget) {
      this.submitMove(userId, targetId, targetType);
      return;
    }

    this.pendingDrop = { userId, targetId, targetType, targetFull, targetTitle };

    const dialog = this.choiceDialogTarget;
    const titleEl = dialog.querySelector("[data-role='target-name']");
    if (titleEl) titleEl.textContent = targetTitle;

    dialog.showModal();
  }

  chooseMove() {
    if (!this.pendingDrop) return;
    const { userId, targetId, targetType, targetFull } = this.pendingDrop;

    this.closeDialog();
    if (targetFull && !confirm(this.overbookingWarningValue)) return;
    this.submitMove(userId, targetId, targetType);
  }

  chooseAdd() {
    if (!this.pendingDrop) return;
    const { userId, targetId, targetType, targetFull } = this.pendingDrop;

    this.closeDialog();
    if (targetFull && !confirm(this.overbookingWarningValue)) return;
    this.submitAdd(userId, targetId, targetType);
  }

  cancelChoice() {
    this.pendingDrop = null;
    this.closeDialog();
  }

  closeDialog() {
    if (this.hasChoiceDialogTarget) {
      this.choiceDialogTarget.close();
    }
    this.pendingDrop = null;
  }

  submitMove(userId, targetId, targetType) {
    const path = this.movePathValue.replace("__USER_ID__", userId);
    this.submitAction(path, "PATCH", {
      target_id: targetId,
      target_type: this.classNameFor(targetType),
      source: "panel",
    });
  }

  submitAdd(userId, targetId, targetType) {
    const plural = targetType + "s";
    const path = `/${plural}/${targetId}/roster/members`;

    // Determine the source type to instruct the backend how to render the panel updates
    const sourceParams = this.sourceTypeValue === "unassigned"
      ? {
          source: "unassigned",
          source_id: this.sourceIdValue,
        }
      : {
          source: "panel",
        };

    this.submitAction(path, "POST", {
      user_id: userId,
      ...sourceParams,
    });
  }

  async submitAction(path, method, params) {
    const form = document.createElement("form");
    form.action = path;
    form.method = "POST";
    form.hidden = true;
    form.dataset.turbo = "true";

    if (method !== "POST") {
      form.appendChild(this.hiddenInput("_method", method));
    }

    const token = document.querySelector("meta[name='csrf-token']")?.content;
    if (token) form.appendChild(this.hiddenInput("authenticity_token", token));

    for (const [key, value] of Object.entries(params)) {
      form.appendChild(this.hiddenInput(key, value));
    }

    document.body.appendChild(form);
    form.requestSubmit();
    form.remove();
  }

  hiddenInput(name, value) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }

  classNameFor(type) {
    const map = { tutorial: "Tutorial", cohort: "Cohort", talk: "Talk" };
    return map[type] || type;
  }
}
