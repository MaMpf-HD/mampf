class PlusTenButton extends Button  {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;
    
    element.addEventListener('click', function() {
      video.currentTime = Math.min(video.currentTime + 10, video.duration);
    });
  }
  
}
