class MuteButton extends Component {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;
    
    element.addEventListener('click', function() {
      if (video.muted === false) {
        video.muted = true;
        element.innerHTML = 'volume_off';
      } else {
        video.muted = false;
        element.innerHTML = 'volume_up';
      }
    });
  }
  
}
