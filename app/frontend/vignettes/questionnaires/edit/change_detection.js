import { reloadTurboFrame } from "~/entrypoints/initHotwire";
import { HandlerRegistry } from "./handler_registry";
import { fixVideoAttachments } from "./video_fix";

const COLLAPSE_CLASS = ".vignette-accordion-collapse";

let currentUnsavedSlideForm = null;
let pendingSlideId = null;
let pendingAction = null;
let hasUnsavedChanges = false;
let formSubmit = false;

const registry = new HandlerRegistry();

$(document).ready(function () {
  registerChangeHandlers();
  preventLeavingSiteOnUnsavedChanges();

  $("#discard-changes-btn").on("click", function () {
    discardCurrentChanges();
  });

  $("#save-changes-btn").on("click", function () {
    saveCurrentChanges();
  });
});

function registerChangeHandlers() {
  // New slide appended
  $(document).on("turbo:stream-render", function () {
    $(COLLAPSE_CLASS).not(":last").each(function () {
      const $this = $(this);
      if ($this.hasClass("show")) {
        $this.collapse("hide");
      }
    });
    setupChangeDetection();
  });

  // e.g. after update of a slide
  $(document).on("turbo:frame-render", function () {
    resetUnsavedChangesState();
    setupChangeDetection();
  });

  // Accordion button clicked to open slide
  $(document).on("shown.bs.collapse", COLLAPSE_CLASS, function (event) {
    if (event.target !== this) return;
    setupChangeDetection();
  });

  $(document).on("show.bs.collapse", COLLAPSE_CLASS, function (event) {
    if (event.target !== this) return;

    const allowed = handleUnsavedChanges(event, "show");
    if (!allowed) return false;

    const targetId = event.target.id;
    if (!event.target.id) return true;

    $(`${COLLAPSE_CLASS}.show`).each(function () {
      if (this.id !== targetId) {
        $(this).collapse("hide");
      }
    });

    return true;
  });

  $(document).on("hide.bs.collapse", COLLAPSE_CLASS, function (event) {
    if (event.target !== this) return;
    registry.deregisterAll();
    const allowed = handleUnsavedChanges(event, "hide");
    resetUnsavedChangesState();
    return allowed;
  });

  function handleUnsavedChanges(event, action) {
    if (!hasUnsavedChanges) return true;
    if (!event.target.id.includes("slides-collapse-")) return true;

    event.preventDefault();
    event.stopPropagation();
    $("#unsaved-changes-modal").modal("show");
    pendingAction = action;
    pendingSlideId = event.target.id;
    return false;
  }
}

function resetUnsavedChangesState() {
  $("#unsaved-changes-warning").addClass("d-none");
  hasUnsavedChanges = false;
  currentUnsavedSlideForm = null;
  pendingAction = null;
  pendingSlideId = null;
}

function setupChangeDetection() {
  fixVideoAttachments();
  _setupChangeDetection(false);
  _setupChangeDetection(true);
}

function getVisibleAccordionBody() {
  return $(`${COLLAPSE_CLASS}.show .accordion-body`);
}

function _setupChangeDetection(isInfoSlide) {
  const visibleAccordionBody = getVisibleAccordionBody();
  const form = visibleAccordionBody.find(`.${isInfoSlide ? "info-" : ""}slide-form`);
  if (form.length !== 1) return;

  registry.deregisterAll();
  resetUnsavedChangesState();

  const unsavedChangesWarning = $("#unsaved-changes-warning");
  const formSubmitButton = form.find(".slide-submit-btn");

  const initialState = form.serialize();
  // necessary since changing the question type only changes which elements
  // are shown on-screen, but not the serialized form data
  const initialQuestionType = form.find("#vignette-question-type").val();

  function checkForChanges() {
    const currentState = form.serialize();
    const currentQuestionType = form.find("#vignette-question-type").val();
    if (currentState !== initialState || currentQuestionType !== initialQuestionType) {
      unsavedChangesWarning.removeClass("d-none");
      formSubmitButton.removeClass("d-none");
      currentUnsavedSlideForm = form;
      hasUnsavedChanges = true;
    }
    else if (hasUnsavedChanges) {
      unsavedChangesWarning.addClass("d-none");
      formSubmitButton.addClass("d-none");
      currentUnsavedSlideForm = null;
      hasUnsavedChanges = false;
    }
  }

  registry.register(
    form.find("input, select, textarea, trix-editor"), "change keyup", checkForChanges);
  registry.register(
    form, "vignettes:questionTypeChanged", checkForChanges);
  registry.register(
    form.find("#vignette-multiple-choice-options"), "change keyup", checkForChanges, "input");
  registry.register(
    form.find("#vignette-multiple-choice-options"), "click", checkForChanges, ".btn-outline-danger");
  registry.register(
    form.find("#vignette-multiple-choice-options"), "change", checkForChanges, ".vignette-mc-hidden-destroy");
  registry.register($(document), "direct-upload:end", checkForChanges);
  registry.register($(document), "trix-attachment-remove", checkForChanges);
}

function saveCurrentChanges() {
  if (!currentUnsavedSlideForm) return;

  // Store values since they are reset upon modal closing
  const pendingSlide = $(`#${pendingSlideId}`);
  const pendingActionStored = pendingAction;

  $(document).one("turbo:frame-render", function () {
    collapseAllSlides();
    executePendingAction(pendingSlide, pendingActionStored);
  });

  const submitButton = currentUnsavedSlideForm.find(".slide-submit-btn");
  submitButton.click();
}

function discardCurrentChanges() {
  hasUnsavedChanges = false;
  currentUnsavedSlideForm = null;

  $("#unsaved-changes-modal").modal("hide");
  $("#unsaved-changes-warning").addClass("d-none");

  // Store values since they are reset upon modal closing
  const pendingSlide = $(`#${pendingSlideId}`);
  const pendingActionStored = pendingAction;
  const currentFrame = getVisibleAccordionBody().closest("turbo-frame");

  if (currentFrame.length === 1) {
    $(document).one("hidden.bs.modal", function () {
      // Reload to discard unsaved changes. Otherwise, the changes would still be
      // visible when reopening the slide, although the backend data is unchanged.
      reloadTurboFrame(currentFrame.get(0));
    });
  }

  collapseAllSlides();
  executePendingAction(pendingSlide, pendingActionStored);
}

function preventLeavingSiteOnUnsavedChanges() {
  $(document).on("click", "form button[type='submit'], form input[type='submit']", function () {
    // Mark intentional form submit to not prevent redirect
    formSubmit = true;
  });

  window.addEventListener("beforeunload", event => checkForChangesAndPreventFromLeaving(event));

  const backButton = $("#vignettes-back-btn");
  const confirmMessage = backButton.attr("data-navigate-away-message");

  backButton.click(event => checkForChangesAndPreventFromLeaving(event, () => {
    const wantsToNavigateAway = confirm(confirmMessage);
    if (wantsToNavigateAway) {
      formSubmit = false;
      return false;
    }
  }));

  function checkForChangesAndPreventFromLeaving(event, confirmHandler) {
    if (shouldAllowNavigatingAway()) {
      formSubmit = false;
      return;
    }

    if (confirmHandler) {
      const result = confirmHandler();
      if (result === false) {
        return;
      }
    }

    event.preventDefault();
    event.returnValue = confirmMessage;
    return confirmMessage;
  }

  function shouldAllowNavigatingAway() {
    const unsavedChangesModalOpen = $("#unsaved-changes-modal").hasClass("show");
    return !hasUnsavedChanges || unsavedChangesModalOpen || formSubmit;
  }
}

/**
 * Collapses all slides that are currently open.
 *
 * This may have side-effects like discarding previous state variables.
 * Callers must ensure that their main action is triggered before calling this,
 * or they must save the state locally.
 */
function collapseAllSlides() {
  $(COLLAPSE_CLASS).each(function () {
    const $this = $(this);
    if ($this.hasClass("show")) {
      $this.collapse("hide");
    }
  });
}

function executePendingAction(pendingSlide, pendingAction) {
  if (pendingAction === "show") {
    pendingSlide.collapse("show");
  }
  else if (pendingAction === "hide") {
    pendingSlide.collapse("hide");
  }
}
