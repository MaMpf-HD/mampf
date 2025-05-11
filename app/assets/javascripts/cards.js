$(document).on("turbolinks:load", function () {
  $(".mampf-card").on("mousemove", function (event) {
    const { x, y } = this.getBoundingClientRect();
    this.style.setProperty("--x", event.clientX - x);
    this.style.setProperty("--y", event.clientY - y);
  });

  $(".interactive-hover").click(function (event) {
    event.preventDefault();
    const url = $(this).attr("href");
    openNewWindow(url);
  });
});

function openNewWindow(url) {
  window.open(url, "MaMpf Video Player", "width=1920,height=1080");
}
