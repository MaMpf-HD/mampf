class AddScreenshotButton extends Component {
  constructor(element, canvasId) {
    super(element);
    this.canvas = document.getElementById(canvasId);
  }

  add() {
    const video = thymeAttributes.video;
    const canvas = this.canvas;

    // Event listener for add screenshot button
    this.element.addEventListener("click", function () {
      video.pause();
      // extract video screenshot from canvas
      const context = canvas.getContext("2d");
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      const base64image = canvas.toDataURL("image/png");
      // Get our file
      const file = thymeUtility.dataURLtoBlob(base64image);
      // Create new form data
      const fd = new FormData();
      // Append our Canvas image file to the form data
      fd.append("image", file);
      // And send it
      $.ajax(Routes.add_screenshot_path(thymeAttributes.mediumId), {
        type: "POST",
        data: fd,
        processData: false,
        contentType: false,
      });
    });
  }
}
