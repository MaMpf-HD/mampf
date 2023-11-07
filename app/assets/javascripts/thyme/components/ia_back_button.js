/**
 * The Interactive Area Back Button saves a reference on the
 * current time. If one clicks on a chapter field in the
 * interactive area (which sets the current time to the start
 * of the chapter), one has the possibility to go back by
 * clicking this button.
 */
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
      if (backInfo && backInfo.length > 20) {
        backInfo = this.element.dataset.back;
      } else {
        backInfo = this.element.dataset.backto + backInfo;
      }
      $(this.element).empty().append(backInfo).show();
      thymeUtility.renderLatex(this.element);
    }
  }

}
