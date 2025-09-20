
let currentUnsavedSlideForm = null;
let pendingSlideId = null;
let pendingAction = null;
let hasUnsavedChanges = false;
let formSubmit = false;

// When using turbo, the event is not fired on redirect
$(document).ready(function () {
  const $slideList = $("#slides");
  const editable = $slideList.data("questionnaire-editable");
  if (editable) {
    createSortableVignetteSlides($slideList);
  }
  // registerVignetteSlideOpenListener();
  // registerVignetteEditSlideListener();

  $("#discard-changes-btn").on("click", function () {
    discardCurrentChanges();
  });

  $("#save-changes-btn").on("click", function () {
    saveCurrentChanges();
  });

  preventLeavingSiteOnUnsavedChanges();
});

function createSortableVignetteSlides(slideList) {
  Sortable.create(slideList.get(0), {
    animation: 150,
    filter: ".accordion-collapse",
    preventOnFilter: false,
    onEnd: function (evt) {
      if (evt.oldIndex == evt.newIndex) return;

      let questionnaire_id = evt.target.dataset.questionnaireId;
      $.ajax({
        url: `/questionnaires/${questionnaire_id}/update_slide_position`,
        method: "PATCH",
        data: {
          old_position: evt.oldIndex,
          new_position: evt.newIndex,
        },
        error: function (xhr, status, error) {
          console.error(`Failed to update position: ${error}`);
        },
      });
    },
  });
}

function registerVignetteSlideOpenListener() {
  $(".vignette-accordion-collapse").on("show.bs.collapse", function (event) {
    return handleUnsavedChanges(event, "show");
  });

  $(".vignette-accordion-collapse").on("hide.bs.collapse", function (event) {
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

function discardCurrentChanges() {
  hasUnsavedChanges = false;
  currentUnsavedSlideForm = null;

  $("#unsaved-changes-modal").modal("hide");
  $("#unsaved-changes-warning").addClass("d-none");
  closeAllOpenSlides();

  const pendingSlide = $(`#${pendingSlideId}`);
  if (pendingAction === "show") {
    pendingSlide.collapse("show");
  }
  else if (pendingAction === "hide") {
    pendingSlide.collapse("hide");
  }
}

function saveCurrentChanges() {
  if (!currentUnsavedSlideForm) return;
  const submitButton = currentUnsavedSlideForm.find(".slide-submit-btn");
  submitButton.click();
}

function registerVignetteEditSlideListener() {
  const $slideList = $("#slides");

  $(".vignette-accordion-collapse").on("shown.bs.collapse", function (evt) {
    const slideId = evt.target.dataset.slideId;
    if (slideId === undefined) {
      // multiple choice options are also collapsible
      // and trigger shown.bs.collapse
      return;
    }

    const questionnaireId = $slideList.attr("data-questionnaire-id");
    if (questionnaireId === undefined) {
      console.error("Questionnaire id is missing");
      return;
    }

    const isInfoSlide = $(this).attr("data-is-info-slide") === "true";
    const prefix = getInfoSlidePrefix(isInfoSlide);
    const $list = $(`#${prefix}slides`);
    const url = isInfoSlide ? Routes.edit_questionnaire_info_slide_path(questionnaireId, slideId) : Routes.edit_questionnaire_slide_path(questionnaireId, slideId);
    handleEdit(url, $list, isInfoSlide, questionnaireId, slideId);
  });

  function handleEdit(url, $list, isInfoSlide, questionnaireId, slideId) {
    // const prefix = getInfoSlidePrefix(isInfoSlide);

    $.ajax({
      url: url,
      method: "GET",
      dataType: "html",
      success: function (response) {
        // TODO: Vignettes
        // setupChangeDetection(isInfoSlide);
        // fixVideoAttachments();
      },
      error: function (xhr, status, error) {
        console.error(`Failed to load slide edit form: ${error}`);
      },
    });
  }
}

function getInfoSlidePrefix(isInfoSlide) {
  return isInfoSlide ? "info-" : "";
}

function setupChangeDetection(isInfoSlide) {
  const prefix = getInfoSlidePrefix(isInfoSlide);

  const form = $(`#${prefix}slide-form`);
  const unsavedChangesWarning = $("#unsaved-changes-warning");
  const formSubmitButton = form.find(".slide-submit-btn");

  const initialState = form.serialize();
  form.find("input, select, textarea, trix-editor").on("change keyup", checkForChanges);
  $("#vignette-multiple-choice-options").on("change keyup", "input", checkForChanges);

  $(document).on("direct-upload:end", function () {
    checkForChanges();
  });

  $(document).on("trix-attachment-remove", function () {
    setTimeout(checkForChanges, 300);
  });

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
}

function closeAllOpenSlides() {
  $(".vignette-accordion-collapse").each(function () {
    const $this = $(this);
    if ($this.hasClass("show")) {
      $this.collapse("hide");
    }
  });
}

function fixVideoAttachments() {
  document.querySelectorAll("figure.attachment img").forEach(function (img) {
    // Skip if already processed
    if (img.getAttribute("data-video-fixed")) return;

    const figure = img.closest("figure");
    if (!figure) return;

    const attachmentData = figure.getAttribute("data-trix-attachment");
    if (!attachmentData) return;

    const attachment = JSON.parse(decodeURIComponent(attachmentData.replace(/&quot;/g, '"')));

    if (!attachment.contentType || !attachment.contentType.includes("video/")) return;

    img.setAttribute("data-video-fixed", "true");

    // Create hidden video element to use first frame as preview
    const hiddenVideo = document.createElement("video");
    hiddenVideo.style.display = "none";
    hiddenVideo.preload = "metadata";
    hiddenVideo.src = attachment.url;
    document.body.appendChild(hiddenVideo);

    // When video loads, capture first frame
    hiddenVideo.onloadeddata = function () {
      hiddenVideo.currentTime = 0;
    };

    // When seeked, create thumbnail
    hiddenVideo.onseeked = function () {
      try {
        // Draw frame to canvas
        const canvas = document.createElement("canvas");
        canvas.width = hiddenVideo.videoWidth;
        canvas.height = hiddenVideo.videoHeight;
        const ctx = canvas.getContext("2d");
        ctx.drawImage(hiddenVideo, 0, 0, canvas.width, canvas.height);

        // Set thumbnail image
        img.src = canvas.toDataURL();

        // Clean up
        document.body.removeChild(hiddenVideo);
      }
      catch (err) {
        console.error("Failed to create video thumbnail", err);
        document.body.removeChild(hiddenVideo);
      }
    };

    hiddenVideo.onerror = function () {
      document.body.removeChild(hiddenVideo);
    };
  });
}

function preventLeavingSiteOnUnsavedChanges() {
  // Mark intentional form submit to not prevent redirect
  $(document).on("click", "form button[type='submit'], form input[type='submit']", function () {
    formSubmit = true;
  });

  const backButton = $("#vignettes-back-btn");
  const confirmMessage = backButton.attr("data-navigate-away-message");

  window.addEventListener("beforeunload", event => checkForChangesAndPreventFromLeaving(event));
  backButton.click(function (event) {
    if (shouldAllowNavigatingAway()) {
      formSubmit = false;
      return;
    }
    const wantsToNavigateAway = confirm(confirmMessage);
    if (wantsToNavigateAway) {
      formSubmit = false;
      return;
    }
    event.preventDefault();
    event.stopPropagation();
  });

  function shouldAllowNavigatingAway() {
    const unsavedChangesModalOpen = $("#unsaved-changes-modal").hasClass("show");
    return !hasUnsavedChanges || unsavedChangesModalOpen || formSubmit;
  }

  function checkForChangesAndPreventFromLeaving(event) {
    if (shouldAllowNavigatingAway()) {
      formSubmit = false;
      return;
    }

    event.preventDefault();
    event.returnValue = confirmMessage;
    return confirmMessage;
  }
}
