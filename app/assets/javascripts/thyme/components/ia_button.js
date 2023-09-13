class IaButton extends Component {

  /*
      toHideIds = An array consisting of all the components that
                  should be hidden/shown when this button is clicked.
                  These components must provide a show() and hide()
                  method, but they havn't to be a JQuery reference
                  on a HTML element.

    toShrinkIds = An array consisting of JQuery references of all
                  the components that should grow/shrink when this
                  button is clicked.

         shrink = The percentage telling how much the video player
                  should shrink when the components of toHide are shown.
   */
  constructor(element, toHide, toShrink, shrink) {
    super(element);
    this.toHide = toHide;
    this.toShrink = toShrink;
    this.shrink = shrink;
  }

  add() {
    const video = thymeAttributes.video;
    const element = this.element;
    const button = this;
    const shrink = this.shrink;

    element.addEventListener('click', function() {
      if (element.dataset.status === 'true') {
        element.dataset.status = 'false';
        element.innerHTML = 'remove_from_queue';
        for (let e of button.toHide) {
          e.hide();
        }
        for (let e of button.toShrink) {
          e.css('width', '100%');
        }
        thymeAttributes.video.style.width = '100%';
      } else {
        element.dataset.status = 'true';
        element.innerHTML = 'add_to_queue';
        for (let e of button.toHide) {
          e.show();
        }
        for (let e of button.toShrink) {
          e.css('width', shrink);
        }
        thymeAttributes.video.style.width = button.shrink;
      }
      thymeAttributes.annotationManager.updateMarkers();
    });
  }

  /*
    Sets the button to its plus value, i.e. shows all
    toHide elements and shrinks all toShrink elements.
   */
  plus() {
    if (this.element.dataset.status === 'false') {
      this.element.click();
    }
  }

  /*
    Sets the button to its minus value, i.e. hides all
    toHide elements and enlarges all toShrink elements.
   */
  minus() {
    if (this.element.dataset.status === 'true') {
      this.element.click();
    }
  }

}
