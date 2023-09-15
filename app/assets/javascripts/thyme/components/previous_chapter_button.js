class PreviousChapterButton extends Component {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the previousChapter button
    element.addEventListener('click', function() {
      const previous = thymeAttributes.chapterManager.previousChapterStart();
      if (previous != null) {
        video.currentTime = thymeAttributes.chapterManager.previousChapterStart();
      }
    });
  }
  
}
