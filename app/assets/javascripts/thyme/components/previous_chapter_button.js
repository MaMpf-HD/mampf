class PreviousChapterButton extends Component {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the previousChapter button
    element.addEventListener('click', function() {
      const previous = chapters.previousChapterStart(video.currentTime);
      if (previous != null) {
        video.currentTime = chapters.previousChapterStart(video.currentTime);
      }
    });
  }
  
}
