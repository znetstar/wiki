import React, { Component } from 'react';
import { Navbar, Nav, NavItem } from 'react-bootstrap';
import SearchBar from './SearchBar';

class AppHeader extends Component {
  constructor(props) {
    super(props);
  	
    this.state = { };
  }

  render() {
    return (
    	<Navbar>
    		<Navbar.Header>
    			<Navbar.Brand>
    				<a href="#">Sample Events</a>
    			</Navbar.Brand>
    		</Navbar.Header>
    		<Navbar.Collapse>
    			<SearchBar />
    		</Navbar.Collapse>
    	</Navbar>
    );
  }
}

export default AppHeader;
