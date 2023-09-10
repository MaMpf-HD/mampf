class NextChapterButton extends Button  {

  add() {
    const video = thymeAttributes.video;
    const element = this.element;

    // Event handler for the nextChapter button
    element.addEventListener('click', function() {
      const next = chapters.nextChapterStart(video.currentTime);
      if (next != null) {
        video.currentTime = chapters.nextChapterStart(video.currentTime);
      }
    });
  }
  
}