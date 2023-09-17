class PlusButton extends Component {

  /*
    time = The time to add in seconds.
   */
  constructor(element, time) {
    super(element);
    this.time = time;
  }

  add() {
    const video = thymeAttributes.video;
    const time = this.time;
    
    this.element.addEventListener('click', function() {
      video.currentTime = Math.min(video.currentTime + time, video.duration);
    });
  }
  
}
