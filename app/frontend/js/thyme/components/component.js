/**
 * The basic component class that every THYME-related component
 * (slider, selector, etc.) should inherit from.
 */
export class Component {
  /*
    element = The id of the HTML element associated to this button.
   */
  constructor(element) {
    this.element = document.getElementById(element);
  }

  /* This method should add the button functionality to the given player.
     Override it in the given subclass! */
  add() { }
}
