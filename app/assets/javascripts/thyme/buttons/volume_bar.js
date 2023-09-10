class VolumeBar extends Button  {
  constructor() {
    super('volume-bar');
  }

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event listener for the volume bar
    element.addEventListener('input', function() {
      video.volume = element.value;
    });

    video.addEventListener('loadedmetadata', function() {
      element.value = video.volume;
      element.style.backgroundImage = 'linear-gradient(to right,' +
                                        ' #2497E3, #2497E3 ' +
                                        video.volume * 100 +
                                        '%, #ffffff ' +
                                        video.volume * 100 +
                                        '%, #ffffff)';
    });

    video.addEventListener('volumechange', function() {
      const value = video.volume;
      element.value = value;
      element.style.backgroundImage = 'linear-gradient(to right,' +
                                        ' #2497E3, #2497E3 ' +
                                        value * 100 +
                                        '%, #ffffff ' +
                                        value * 100 +
                                        '%, #ffffff)';
    });
  }
}
