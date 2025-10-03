import Sortable from "sortablejs";

$(document).on("turbo:load", function () {
  const $slideList = $("#slides");
  const editable = $slideList.data("questionnaire-editable");
  if (editable) {
    createSortableVignetteSlides($slideList);
  }
});

/**
 * Makes the Vignettes slides draggable, such that users can drag them around
 * to change their order.
 */
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
