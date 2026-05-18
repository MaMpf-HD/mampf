export class HandlerRegistry {
  handlers = [];

  register(element, events, handler, selector) {
    if (selector) {
      element.on(events, selector, handler);
      this.handlers.push({ element, events, selector, handler });
    }
    else {
      element.on(events, handler);
      this.handlers.push({ element, events, handler });
    }
  }

  deregisterAll() {
    this.handlers.forEach((handler) => {
      if (handler.selector) {
        handler.element.off(handler.events, handler.selector, handler.handler);
      }
      else {
        handler.element.off(handler.events, handler.handler);
      }
    });
    this.handlers = [];
  }
}
