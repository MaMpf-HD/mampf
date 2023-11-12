class NextChapterButton extends Component {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the nextChapter button
    element.addEventListener('click', function() {
      const next = thymeAttributes.chapterManager.nextChapterStart();
      if (next) {
        video.currentTime = thymeAttributes.chapterManager.nextChapterStart();
      }
    });
  }
  
}
