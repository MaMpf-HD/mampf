class NextChapterButton extends Button  {
  constructor() {
    super('next-chapter');
  }

  add() {
    const video = this.video;
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