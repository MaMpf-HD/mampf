class PlusTenButton extends Button  {
  constructor() {
    super('plus-ten');
  }

  add() {
    const video = this.video;
    const element = this.element;
    
    element.addEventListener('click', function() {
      video.currentTime = Math.min(video.currentTime + 10, video.duration);
    });
  }
}
