$(document).on("turbolinks:load", function () {
  const vignetteSlideList = document.getElementById("vignettes-slides-list");

  Sortable.create(vignetteSlideList, {
    animation: 150,
    ghostClass: "vignette-sortable-ghost",
    onEnd: function (evt) {
      console.log(`Moved element from ${evt.oldIndex} to ${evt.newIndex}`);
      // TODO: send a request to update the order of the slides in the database
      // TODO: see more options here:
      // https://github.com/SortableJS/Sortable?tab=readme-ov-file#options
    },
  });
});
