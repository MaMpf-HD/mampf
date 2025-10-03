import { HandlerRegistry } from "./handler_registry";

const COLLAPSE_CLASS = ".vignette-accordion-collapse";

let currentUnsavedSlideForm = null;
let pendingSlideId = null;
let pendingAction = null;
let hasUnsavedChanges = false;
let formSubmit = false;

let registry = new HandlerRegistry();

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
    setupChangeDetection();
  });

  // e.g. after update of a slide
  $(document).on("turbo:frame-render", function () {
    setupChangeDetection();
  });

  // Accordion button clicked to open slide
  $(document).on("shown.bs.collapse", COLLAPSE_CLASS, function () {
    setupChangeDetection();
  });

  $(document).on("show.bs.collapse", COLLAPSE_CLASS, function (event) {
    return handleUnsavedChanges(event, "show");
  });

  $(document).on("hide.bs.collapse", COLLAPSE_CLASS, function (event) {
    registry.deregisterAll();
    resetUnsavedChangesState();
    return handleUnsavedChanges(event, "hide");
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
  _setupChangeDetection(false);
  _setupChangeDetection(true);
}

function _setupChangeDetection(isInfoSlide) {
  const visibleAccordionBody = $(`${COLLAPSE_CLASS}.show .accordion-body`);
  const form = visibleAccordionBody.find(`.${isInfoSlide ? "info-" : ""}slide-form`);
  if (form.length !== 1) return;

  registry.deregisterAll();
  resetUnsavedChangesState();

  const unsavedChangesWarning = $("#unsaved-changes-warning");
  const formSubmitButton = form.find(".slide-submit-btn");

  const initialState = form.serialize();

  function checkForChanges() {
    const currentState = form.serialize();
    if (currentState !== initialState) {
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
    $("#vignette-multiple-choice-options"), "change keyup", checkForChanges, "input");
  registry.register($(document), "direct-upload:end", checkForChanges);
  registry.register($(document), "trix-attachment-remove", checkForChanges);
}

function saveCurrentChanges() {
  if (!currentUnsavedSlideForm) return;
  const submitButton = currentUnsavedSlideForm.find(".slide-submit-btn");
  submitButton.click();
}

function discardCurrentChanges() {
  hasUnsavedChanges = false;
  currentUnsavedSlideForm = null;

  $("#unsaved-changes-modal").modal("hide");
  $("#unsaved-changes-warning").addClass("d-none");

  function closeAllOpenSlides() {
    $(".vignette-accordion-collapse").each(function () {
      const $this = $(this);
      if ($this.hasClass("show")) {
        $this.collapse("hide");
      }
    });
  }
  closeAllOpenSlides();

  const pendingSlide = $(`#${pendingSlideId}`);
  if (pendingAction === "show") {
    pendingSlide.collapse("show");
  }
  else if (pendingAction === "hide") {
    pendingSlide.collapse("hide");
  }
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
