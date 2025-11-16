/**
 * Fixes video attachments in Trix editors by generating a thumbnail
 * from the first frame of the video.
 */
export function fixVideoAttachments() {
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
