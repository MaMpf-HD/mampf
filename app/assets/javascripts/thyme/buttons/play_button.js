class PlayButton extends Button  {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    element.addEventListener('click', function() {
      if (video.paused === true) {
        video.play();
      } else {
        video.pause();
      }
    });

    video.onplay = function() {
      element.innerHTML = 'pause';
    };
    
    video.onpause = function() {
      element.innerHTML = 'play_arrow';
    };
  }

}