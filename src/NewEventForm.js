import React, { Component } from 'react';
import { Form, FormControl, FormGroup, Row, Col, Grid, ControlLabel, Collapse, ButtonToolbar, Button } from 'react-bootstrap';

const guid = () => {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
};

class NewEventForm extends Component {
    constructor(props) {
      super(props);

      this.addEvents = props.addEvents;

      this.state = { prestine: true };
    }

    openForm = () => {
        this.setState({ open: !Boolean(this.state.open) });
    }

    addEvent = () => {
        if (this.state.title && this.state.start && this.state.end) {
            let event = {
                title: this.state.title,
                start_time: new Date(this.state.start),
                end_time: new Date(this.state.end),
                description: this.state.description,
                id: guid()
            };

            this.addEvents(event);
            this.setState({ title: '', start: '', end: '', description: '', prestine: true });
        }
        else {
            this.setState({ prestine: false, title: (this.state.title || ''), start: (this.state.start || ''), end: (this.state.end || ''), description: (this.state.description || void(0)) });
        }
    }

    setStateProperty = (e, property) => {
        let property_title = e.target.getAttribute('data-property');
        let obj = new Object();
        obj[property_title] = e.target.value;

        this.setState({ prestine: false });

        this.setState(obj);
    }

    validateTitle = () => {
        if (!this.state.prestine && (typeof(this.state.title) !== 'undefined') && !this.state.title.length)
            return 'error';
    }

    validateDate = () => {
        if (
            !this.state.prestine && 
            (((typeof(this.state.start) !== 'undefined') && !this.state.start.length) ||
            ((typeof(this.state.end) !== 'undefined') && !this.state.end.length)) ||
            (
                (new Date(this.state.start)) > 
                (new Date(this.state.end))
            )
        )
            return 'error';
    }

    render() {
        return (
            <Grid>
                <Row>
                    <Col xs={12}>
                        <ButtonToolbar>
                            <Button onClick={this.openForm} bsStyle="primary" active={this.state.open}>New Event</Button>
                        </ButtonToolbar>
                    </Col>
                </Row>
                <br/>
                <Collapse in={this.state.open}>
                    <Col xs={12}>
                        <Row>
                            <Form horizontal>
                                <FormGroup validationState={this.validateTitle()}>
                                    <Col sm={6}>
                                        <FormControl onChange={this.setStateProperty} data-property="title" value={this.state.title} type="text" placeholder="Event Title" />
                                    </Col>
                                </FormGroup>

                                <FormGroup validationState={this.validateDate()}>
                                    <Col sm={6}>
                                        <ControlLabel>Start Date</ControlLabel>
                                        <FormControl onChange={this.setStateProperty} data-property="start" type="date" value={this.state.start}/>
                                    </Col>

                                    <Col sm={6}>
                                        <ControlLabel>End Date</ControlLabel>
                                        <FormControl type="date" onChange={this.setStateProperty} data-property="end" value={this.state.end} />
                                    </Col>
                                </FormGroup>

                                <FormGroup>
                                    <Col sm={12}>
                                        <FormControl componentClass="textarea" onChange={this.setStateProperty} data-property="description" placeholder="Event Description" value={this.state.description} />
                                    </Col>
                                </FormGroup>

                                <div>
                                    <Button onClick={this.addEvent}>Add Event</Button>
                                </div>
                                <br/>
                            </Form>
                        </Row>
                    </Col>
                </Collapse>
            </Grid>
        );
    }
}

export default NewEventForm;
