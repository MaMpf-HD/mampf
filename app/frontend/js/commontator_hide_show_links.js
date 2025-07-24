$(document).ready(function () {
  const threadId = $("#commontator-dynamics").data("thread-id");
  if (!threadId) {
    console.error("Commontator: Thread ID is not defined.");
    return;
  }

  $(`#commontator-thread-${threadId}-hide-link`).click(function () {
    $("#commontator-thread-${threadId}-content").hide();

    var commontatorLink = $(`#commontator-thread-${threadId}-show`).fadeIn();
    $("html, body").animate(
      { scrollTop: commontatorLink.offset().top - window.innerHeight / 2 }, "fast",
    );
  });

  $(`#commontator-thread-${threadId}-show-link`).click(function () {
    var commontatorThread = $("#commontator-thread-${threadId}-content").fadeIn();
    $("html, body").animate(
      { scrollTop: commontatorThread.offset().top - window.innerHeight / 2 }, "fast",
    );

    $(`#commontator-thread-${threadId}-show`).hide();
  });

  $(`#commontator-thread-${threadId}-hide`).show();
});
