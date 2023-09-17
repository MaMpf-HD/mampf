class IaBackButton extends Component {

  constructor(element, chapterListId) {
    super(element);
    this.chapterListId = chapterListId;
  }

  add() {
    // Event Handler for Back Button
    this.element.addEventListener('click', function() {
      video.currentTime = this.dataset.time;
      $(this).hide();
    });
  }

  update() {
    // set up back button (transports back to the current chapter)
    this.element.dataset.time = video.currentTime;
    const currentChapter = $('#' + this.chapterListId + ' .current');
    if (currentChapter.length > 0) {
      let backInfo = currentChapter.data('text').split(':', 1)[0];
      if ((backInfo != null) && backInfo.length > 20) {
        backInfo = this.element.dataset.back;
      } else {
        backInfo = this.element.dataset.backto + backInfo;
      }
      $(this.element).empty().append(backInfo).show();
      thymeUtility.renderLatex(this.element);
    }
  }

}