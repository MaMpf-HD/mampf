$(".mampf-card").on("mousemove", function (event) {
  const { x, y } = this.getBoundingClientRect();
  this.style.setProperty("--x", event.clientX - x);
  this.style.setProperty("--y", event.clientY - y);
});
