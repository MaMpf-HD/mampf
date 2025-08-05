document.addEventListener("turbo:frame-missing", function (event) {
  event.preventDefault();
  event.detail.visit(event.detail.response);
});
