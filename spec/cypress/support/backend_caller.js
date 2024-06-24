/**
 * Class to call special Cypress backend routes from Cypress frontend tests.
 */
class BackendCaller {
  /**
   * Calls the given route as POST request to the backend.
   *
   * @param routeName: name of the route to call
   * @param errorSubject: subject in the error message
   * @param args: arguments to pass as body to the POST route
   * @returns the response body of the route as Cypress promise (not native promise!)
   */
  static callCypressRoute(routeName, errorSubject, args) {
    return cy.request({
      url: `cypress/${routeName}`,
      method: "post",
      form: true,
      failOnStatusCode: false,
      body: args,
    }).then((res) => {
      if (res.status === 201)
        return res.body;

      let errorMsg = `${errorSubject} failed: ${res.body.error}.`;
      errorMsg += `\n\nStacktrace:\n${res.body.stacktrace}`;
      throw new Error(errorMsg);
    });
  }
}

export default BackendCaller;
