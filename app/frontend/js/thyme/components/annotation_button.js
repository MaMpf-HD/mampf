import { Component } from "~/js/thyme/components/component";

export class AnnotationButton extends Component {
  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the annotation button
    element.addEventListener("click", function () {
      video.pause();
      $.ajax(Routes.new_annotation_path(), {
        type: "GET",
        dataType: "script",
        data: {
          total_seconds: video.currentTime,
          medium_id: thymeAttributes.mediumId,
        },
      });
    });
  }
}
