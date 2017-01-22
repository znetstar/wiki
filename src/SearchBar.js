import React, { Component } from 'react';
import { Navbar, FormGroup, FormControl } from 'react-bootstrap';

class SearchBar extends Component {
    constructor(props) {
      super(props);

      this.state = { query: ((window.document.location.hash.length > 1) ? (window.document.location.hash.substr(1)) : void(0)) };
    }

    handleChange = (e) => {
        let query = e.target.value;
        window.document.location.hash = query;
        this.setState({ query });
    }

    render() {
        return (
            <Navbar.Collapse>
                <Navbar.Form pullRight>
                    <FormGroup>
                        <FormControl 
                                    type="text"
                                    value={this.state.query}
                                    placeholder="Search..."
                                    onChange={this.handleChange}
                        >
                        </FormControl>
                    </FormGroup>
                </Navbar.Form>
            </Navbar.Collapse>
        );
    }
}

export default SearchBar;
