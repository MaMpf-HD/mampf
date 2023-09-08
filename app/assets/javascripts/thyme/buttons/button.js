/**
  The basic button class from which every thyme related button (slider, selector, etc.)
  should be a subclass.
*/
class Button {
  constructor(element) {
    this.video = document.getElementById('video');
    this.element = document.getElementById(element);
  }

  /* This method should add the button functionality to the given player.
     Override it in the given subclass! */
  add() { }
}