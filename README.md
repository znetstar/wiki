
Your mission, should you choose to accept it, is to produce a React App with three primary components:

1. A **List of events**. This component should initially render events that are retrieved from the [Eventable API](http://docs.eventable.apiary.io) using the provided credentials (in the email you received). It should also render events that are created and stored locally. The List should be sortable by title and start time.
2. A **Form** component. Submitting the Form should create an event locally (*DO NOT MAKE AN API REQUEST WHEN CREATING AN EVENT*). An event should have a title, a start date-time and an end date-time. The form should not submit if there is no title or if the date-time is invalid (i.e. end date-time is before the start date-time).
3. A **Search** component. Entering text into this component should filter the events in the List component by event title.

Fork this repo to get started. Try not to spend longer than three hours on this challenge. Good luck!

Some notes:
- Do not install any additional packages — only use native ES6 functions and/or the packages that have been provided for you
    * [React/ReactDOM](https://github.com/facebook/react)
    * [lodash](https://github.com/lodash/lodash) is included, but most of what you need to do is doable with native ES6 functions
    * [React Bootstrap](https://github.com/react-bootstrap/react-bootstrap), [Twitter (the OG) Bootstrap](https://github.com/twbs/bootstrap)
    * [whatwg-fetch](https://github.com/github/fetch) for making api requests 
    * [momentjs](http://momentjs.com/docs/)
- The events you receive from the Eventable API will have a bunch of data attached to them. It's up to you whether to render that information.
- Be creative! How your components render and style are entirely up to you. 

When you're done, email us a link to your cloned repo with the solution.

This repo was bootstrapped using [create-react-app](https://github.com/facebookincubator/create-react-app).

Run the dev server:
```
npm start
```

Run tests:
```
npm test
```
