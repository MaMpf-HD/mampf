class MinusTenButton extends Button  {
  constructor() {
    super('minus-ten');
  }

  add() {
    const video = thymeAttributes.video;
    const element = this.element;
    
    element.addEventListener('click', function() {
      video.currentTime = Math.max(video.currentTime - 10, 0);
    });
  }
}
