class MinusButton extends Component {

  /*
    time = The time to subtract in seconds.
   */
  constructor(element, time) {
    super(element);
    this.time = time;
  }

  add() {
    const video = thymeAttributes.video;
    const time = this.time;
    
    this.element.addEventListener('click', function() {
      video.currentTime = Math.max(video.currentTime - time, 0);
    });
  }
  
}
