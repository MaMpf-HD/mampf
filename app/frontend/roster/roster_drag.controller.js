import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

// Kept outside the controller: the response to a move replaces the panel and
// its controller, and the new controller restores the focus from here.
let focusAfterReplace = null;

export default class extends Controller {
  static targets = ["studentList", "choiceDialog", "targetDialog", "targetList"];

  static values = {
    sourceType: String,
    sourceId: String,
    movePath: String,
    overbookingWarning: String,
  };

  sortableInstance = null;
  rowDropInstances = [];
  pendingDrop = null;
  highlightedRow = null;
  pendingPick = null;
  pickOpener = null;
  pickedIndex = null;

  connect() {
    this.initDraggable();
    this.initDropZones();
    this.restoreFocusAfterReplace();
  }

  disconnect() {
    this.sortableInstance?.destroy();
    this.rowDropInstances.forEach(s => s.destroy());
    this.rowDropInstances = [];
    this.clearHighlight();
    document.body.classList.remove("roster-dragging");
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
      onStart: () => document.body.classList.add("roster-dragging"),
      onMove: evt => this.updateHighlight(evt.to),
      onEnd: (evt) => {
        document.body.classList.remove("roster-dragging");
        this.clearHighlight();
        if (evt.item.parentNode !== this.studentListTarget) {
          evt.item.remove();
        }
      },
    });
  }

  initDropZones() {
    this.rowDropInstances.forEach(s => s.destroy());
    this.rowDropInstances = [];

    this.targetRows().filter(row => !this.isLocked(row)).forEach((row) => {
      const dropZone = row.querySelector(".group-row__drop") || row;

      const instance = new Sortable(dropZone, {
        group: { name: "roster-drop", put: ["roster-students"] },
        draggable: ".roster-drag-phantom",
        ghostClass: "d-none",
        onAdd: (evt) => {
          evt.item.remove();
          this.handleDrop(row, evt.item?.dataset?.userId);
        },
      });

      this.rowDropInstances.push(instance);
    });
  }

  targetRows() {
    return Array.from(document.querySelectorAll(
      ".group-row[data-roster-type][data-roster-id]",
    )).filter(row => !(
      row.dataset.rosterType === this.sourceTypeValue
      && row.dataset.rosterId === String(this.sourceIdValue)
    ));
  }

  isLocked(row) {
    return row.dataset.rosterLocked === "true";
  }

  // Stimulus action, wired to our custom turbo:stream-render (see initHotwire.js)
  // from the side panel markup.
  refreshDropZones() {
    this.clearHighlight();
    if (!this.hasStudentListTarget) return;

    this.initDropZones();
  }

  updateHighlight(dropZone) {
    const row = dropZone.closest(".group-row");
    if (row === this.highlightedRow) return;

    this.clearHighlight();
    if (row) {
      row.classList.add("group-row--drop-target");
      this.highlightedRow = row;
    }
  }

  clearHighlight() {
    if (this.highlightedRow) {
      this.highlightedRow.classList.remove("group-row--drop-target");
      this.highlightedRow = null;
    }
  }

  /**
   * The keyboard's and the touch screen's way to what a drop does: lists the
   * same rows as buttons, and a choice takes the drop's path. A group that a
   * registration process manages stays in the list, disabled, with the reason.
   */
  pickTarget(event) {
    if (!this.hasTargetDialogTarget || !this.hasTargetListTarget) return;

    const opener = event.currentTarget;
    this.pendingPick = opener.dataset.userId;
    this.pickOpener = opener;
    this.pickedIndex = this.studentIndexOf(opener);

    const dialog = this.targetDialogTarget;
    const titleEl = dialog.querySelector("[data-role='dialog-title']");
    if (titleEl) {
      titleEl.textContent = dialog.dataset.titleTemplate.replace("__NAME__", opener.dataset.userName);
    }

    this.renderPickList();
    dialog.showModal();
    this.targetListTarget.querySelector("button:not(:disabled)")?.focus();
  }

  renderPickList() {
    const dialog = this.targetDialogTarget;
    const list = this.targetListTarget;
    const rows = this.targetRows();
    list.replaceChildren();
    dialog.querySelector("[data-role='no-targets']")?.classList.toggle("d-none", rows.length > 0);

    rows.forEach((row) => {
      const item = document.createElement("li");
      const button = document.createElement("button");
      button.type = "button";
      button.className = "btn btn-sm btn-outline-secondary w-100 text-start";
      const title = document.createElement("span");
      title.className = "fw-semibold";
      title.textContent = row.dataset.rosterTitle;
      const note = document.createElement("span");
      note.className = "d-block small text-muted";
      if (this.isLocked(row)) {
        button.disabled = true;
        note.textContent = dialog.dataset.lockedNote;
      }
      else {
        note.textContent = row.dataset.rosterCount || "";
      }
      button.append(title, note);
      const key = row.dataset.rosterKey;
      button.addEventListener("click", () => this.choosePickedTarget(key));
      item.appendChild(button);
      list.appendChild(item);
    });
  }

  /**
   * Looks the row up again: a stream may have replaced it while the dialog was
   * open, and a full or locked group has to show as such.
   */
  choosePickedTarget(rosterKey) {
    const row = this.targetRows().find(candidate => candidate.dataset.rosterKey === rosterKey);
    if (!row || this.isLocked(row)) {
      this.renderPickList();
      this.targetListTarget.querySelector("button:not(:disabled)")?.focus();
      return;
    }

    const userId = this.pendingPick;
    const index = this.pickedIndex;
    this.cancelPick();
    this.pickedIndex = index;
    this.handleDrop(row, userId);
  }

  cancelPick() {
    this.pendingPick = null;
    this.pickedIndex = null;
    if (this.hasTargetDialogTarget && this.targetDialogTarget.open) {
      this.targetDialogTarget.close();
    }
    this.pickOpener?.focus();
    this.pickOpener = null;
  }

  studentIndexOf(element) {
    if (!this.hasStudentListTarget) return null;

    const cards = Array.from(this.studentListTarget.querySelectorAll(".tutorial-roster-student"));
    return cards.indexOf(element.closest(".tutorial-roster-student"));
  }

  /**
   * Focuses the move button at the list position the keyboard left, which is
   * the next student after a move, or the heading once the list is empty.
   */
  restoreFocusAfterReplace() {
    if (focusAfterReplace === null) return;

    const index = focusAfterReplace;
    focusAfterReplace = null;
    const buttons = this.element.querySelectorAll("[data-action~='roster-drag#pickTarget']");
    const target = buttons[Math.min(index, buttons.length - 1)]
      || this.element.querySelector("[data-roster-panel-heading]");
    target?.focus();
  }

  handleDrop(row, userId) {
    if (!userId) return;

    const targetType = row.dataset.rosterType;
    const targetId = row.dataset.rosterId;
    const targetFull = row.dataset.rosterFull === "true";
    const targetTitle = row.dataset.rosterTitle;
    const targetAddPath = row.dataset.rosterAddMemberPath;

    if (this.campaignSourceType()) {
      if (!this.confirmOverbooking(targetFull)) {
        return;
      }
      this.submitAdd(userId, targetAddPath);
      return;
    }

    const alwaysMove = targetType === "tutorial";

    if (alwaysMove) {
      if (!this.confirmOverbooking(targetFull)) return;
      this.submitMove(userId, targetId, targetType);
    }
    else {
      this.showChoiceDialog(userId, targetId, targetType, targetFull,
        targetTitle, targetAddPath);
    }
  }

  showChoiceDialog(userId, targetId, targetType, targetFull,
    targetTitle, targetAddPath) {
    if (!this.hasChoiceDialogTarget) {
      this.submitMove(userId, targetId, targetType);
      return;
    }

    this.pendingDrop = { userId, targetId, targetType, targetFull,
      targetTitle, targetAddPath };

    const dialog = this.choiceDialogTarget;
    const titleEl = dialog.querySelector("[data-role='target-name']");
    if (titleEl) titleEl.textContent = targetTitle;

    dialog.showModal();
  }

  chooseMove() {
    if (!this.pendingDrop) return;
    const { userId, targetId, targetType, targetFull } = this.pendingDrop;

    this.closeDialog();
    if (!this.confirmOverbooking(targetFull)) return;
    this.submitMove(userId, targetId, targetType);
  }

  chooseAdd() {
    if (!this.pendingDrop) return;
    const { userId, targetFull, targetAddPath } = this.pendingDrop;

    this.closeDialog();
    if (!this.confirmOverbooking(targetFull)) return;
    this.submitAdd(userId, targetAddPath);
  }

  cancelChoice() {
    this.pendingDrop = null;
    this.pickedIndex = null;
    this.closeDialog();
  }

  closeDialog() {
    if (this.hasChoiceDialogTarget && this.choiceDialogTarget.open) {
      this.choiceDialogTarget.close();
    }
    this.pendingDrop = null;
  }

  confirmOverbooking(targetFull) {
    if (!targetFull || confirm(this.overbookingWarningValue)) return true;

    this.pickedIndex = null;
    return false;
  }

  submitMove(userId, targetId, targetType) {
    const path = this.movePathValue.replace("__USER_ID__", userId);
    this.submitAction(path, "PATCH", {
      target_id: targetId,
      target_type: this.classNameFor(targetType),
      source: "panel",
    });
  }

  submitAdd(userId, targetAddPath) {
    const sourceParams = this.campaignSourceType()
      ? {
          source: this.sourceTypeValue,
          source_id: this.sourceIdValue,
        }
      : {
          source: "panel",
          source_type: this.classNameFor(this.sourceTypeValue),
          source_id: this.sourceIdValue,
        };

    this.submitAction(targetAddPath, "POST", {
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

    focusAfterReplace = this.pickedIndex;
    this.pickedIndex = null;

    document.body.appendChild(form);
    form.addEventListener("turbo:submit-end", (event) => {
      if (!event.detail.success) focusAfterReplace = null;
      form.remove();
    }, { once: true });
    form.requestSubmit();
  }

  hiddenInput(name, value) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }

  campaignSourceType() {
    return ["unassigned", "rejected"].includes(this.sourceTypeValue);
  }

  classNameFor(type) {
    const map = { tutorial: "Tutorial", cohort: "Cohort", talk: "Talk" };
    return map[type] || type;
  }
}
