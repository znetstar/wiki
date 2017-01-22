import React, { Component } from 'react';
import { Grid, Row, Col } from 'react-bootstrap';
import AppHeader from './AppHeader';
import EventList from './EventList';
import './App.css';

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {  };
  }

  render() {
    return (
      <div>
        <AppHeader />
        <EventList />
      </div>
    );
  }
}

export default App;
