import React, { Component } from 'react';
import { Panel, Grid, Row } from 'react-bootstrap';
import EventItem from './EventItem';
import NewEventForm from './NewEventForm';
import 'whatwg-fetch';

/*const CREDENTIALS = {
  username: ,
  password: 
};*/

localStorage.eventable_token = '7761e7e3b25a1d6d315901fcd7180d971f77ea2e';

class EventList extends Component {
  constructor(props) {
    super(props);

    this.state = { events: [] };
    this.rawEvents = [];
  }

  handleHashChange = () => {
    let query = window.document.location.hash.substr(1);

    // Filter the events by the search query
    let events = (query === '') ? this.rawEvents : this.rawEvents.filter((event) => event.props.title.match(new RegExp(query, 'ig')));

    this.setState({ events });
  }

  componentWillMount = () => {
    window.addEventListener('hashchange', this.handleHashChange);
  }

  renderEvents = () => {
    let events = this.rawEvents
                  .sort((a,b) => (new Date(b.props.start)) - (new Date(a.props.start)) || a.props.title.localeCompare(b.props.title));

    this.setState({ events });
  }

  addEvents = (events) => {
    this.rawEvents = this.rawEvents.concat([].concat(events).map((event) => <EventItem key={event.id} title={event.title} start={event.start_time} end={event.end_time} description={event.description} />));

    this.renderEvents();
  }

  componentDidMount = () => {
    let getEvents = (token) => {
      fetch('https://api.eventable.com/v1/events/', {
        headers: {
          'Authorization': `Token ${token}`
        }
      })
      .then((response) => response.json())
      .then((data) => {
        let events = data
                .results
                .map((event) => <EventItem key={event.id} title={event.title} start={event.start_time} end={event.end_time} description={event.description} />);

        this.rawEvents = events;
        this.renderEvents();

        if (window.document.location.hash.length > 1)
          this.handleHashChange();
      });
    };

    /*if (!localStorage.eventable_token) {
      fetch('https://api.eventable.com/v1/token-auth/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(CREDENTIALS)
      })
      .then((response) => response.json())
      .then((data) => {
        localStorage.eventable_token = data.token;
        getEvents(localStorage.eventable_token);
      });
    } else {*/
      getEvents(localStorage.eventable_token);
    /*}*/
  }

  componentWillUnmount = () => {
    window.removeEventListener('hashchange', this.handleHashChange);
  }

  render() {
    return (
      <Grid>
        <Row><NewEventForm addEvents={this.addEvents} /></Row>
        <Row>{this.state.events}</Row>
      </Grid>
    );
  }
}

export default EventList;
