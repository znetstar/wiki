import React, { Component } from 'react';
import { Panel, Col } from 'react-bootstrap';
import moment from 'moment';
import './EventItem.css';

class EventItem extends Component {
    constructor(props) {
      super(props);

      this.state = { title: props.title, start: props.start, end: props.end, description: props.description };
    }

    render() {
        return (
            <Col md={6} className="event">
                <Panel header={this.state.title}>
                    <div>
                        <time className="start" dateTime={new Date(this.state.start).toString()}>{moment(this.state.start).format('dddd, MMMM Do YYYY')}</time>
                    </div>
                    <br/>
                    <p>{this.state.description}</p>
                </Panel>
            </Col>
        );
    }
}

export default EventItem;
