/**
 * The Interactive Area Button can show/hide specific elements of the
 * thyme player (normally interactive and annotation area) and
 * adjust the video position/size accordingly.
 */
class IaButton extends Component {

  /*
        toHide = An array consisting of all the components that
                 should be hidden/shown when this button is clicked.
                 These components must provide a show() and hide()
                 method, but they havn't to be a JQuery reference
                 on a HTML element.

      toShrink = An array consisting of JQuery references of all
                 the components that should grow/shrink when this
                 button is clicked.

        shrink = The percentage telling how much the elements of toShrink
                 should shrink when the components of toHide are shown.
   */
  constructor(element, toHide, toShrink, shrink) {
    super(element);
    this.toHide = toHide;
    this.toShrink = toShrink;
    this.shrink = shrink;
  }

  add() {
    const element = this.element;
    const button = this;

    element.addEventListener('click', function() {
      if (element.dataset.status === 'true') {
        button.plus();
      } else {
        button.minus();
      }
    });
  }

  /*
    Sets the button to its plus value, i.e. shows all
    toHide elements and shrinks all toShrink elements.
   */
  plus() {
    this.#aux('false', 'remove_from_queue', false, '100%');
  }

  /*
    Sets the button to its minus value, i.e. hides all
    toHide elements and enlarges all toShrink elements.
   */
  minus() {
    this.#aux('true', 'add_to_queue', true, this.shrink);
  }

  getStatus() {
    return this.element.dataset.status === 'true';
  }



  #aux(status, innerHTML, sh, size) {
    this.element.dataset.status = status;
    this.element.innerHTML = innerHTML;
    for (let e of this.toHide) {
      sh ? e.show() : e.hide();
    }
    for (let e of this.toShrink) {
      e.css('width', size);
    }
    $(window).trigger('resize');
    thymeAttributes.annotationManager.updateMarkers();
  }

}
