// eslint-disable-next-line no-unused-vars
class AddItemButton extends Component {
  add() {
    const video = thymeAttributes.video;

    // Event listener for addItem button
    this.element.addEventListener("click", function () {
      video.pause();
      // round time down to three decimal digits
      const time = video.currentTime;
      const intTime = Math.floor(time);
      const roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000;
      video.currentTime = roundTime;
      $.ajax(Routes.add_item_path(thymeAttributes.mediumId), {
        type: "GET",
        dataType: "script",
        data: {
          time: video.currentTime,
        },
      });
    });
  }
}
