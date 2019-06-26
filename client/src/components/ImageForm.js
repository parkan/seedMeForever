import React, { Component } from 'react'
import './../index.css';
import { apiUrl } from './../env';

class ImageForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      animal: '',
      id: '',
      file: null,
      humanName: '',
      comments: ''
    };
  }

  componentDidMount() {
    return fetch(`${apiUrl}/animals`, {
    method: "GET",
    headers: {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }})
      .then(response => {
        return response.json()
      })
      .then(data => {
        this.setState({ animal: data.name.toLowerCase(), id: data.id })
      })

  }

  onFilesAdded(event) {
    const file = event.target.files[0];
    this.setState({ file, })
  }

  onTextChange(event) {
    const humanName = event.target.value.toLowerCase();
    this.setState({ humanName })
  }

  onCommentsChange(event) {
    const comments = event.target.value.toLowerCase();
    this.setState({ comments })
  }

  handleUpload(event) {
    event.preventDefault();
    event.nativeEvent.stopImmediatePropagation();
    if (!this.state.file) {
      return alert('Please attach an image of your animal')
    }
    if (!this.state.humanName) {
      return alert("Please lookup your animal's common English name")
    }
    const data = new FormData()
    data.append('animal', this.state.file)
    data.append('humanName', this.state.humanName)
    data.append('scientificName', this.state.animal)
    data.append('id', this.state.id)
    data.append('comments', this.state.comments)
    return fetch(`${apiUrl}/animals/${this.state.id}`, {
      method: 'POST',
      body: data,
    })
    .then(response => {
      this.props.handleConsent(false)
      console.log(`${apiUrl}/animals/${this.state.id}`)
      if (response.status === 200) {
        return alert('Success! Your animal was submitted')
      } else {
        return alert('Something is broken x_x please try again later')
      }

    })
    .catch(err => alert('Something is broken x_x please try again later'))

  }

  render() {
    return (
      <form>
        <div>
            <p className="instructions">Your animal is:</p>
            <div className="animal">{this.state.animal}</div>
            <div className="form">
              English name:&nbsp;&nbsp;
              <input
                type="text"
                name="humanName"
                onChange={this.onTextChange.bind(this)} />
              <br />
              <br />
              Choose a photo of your animal:<br />
              <input
                className="fileupload"
                type="file"
                name="animal"
                onChange={this.onFilesAdded.bind(this)} />
              <br />
              <br />
              Would you like to add any other comments?<br />
              <input
                className="comments"
                type="text"
                name="comments"
                onChange={this.onCommentsChange.bind(this)} />
            </div>
            <input
              className="instructionsButton"
              type="button"
              value="Pin"
              onClick={this.handleUpload.bind(this)}
              />
          </div>
      </form>
    )
  }
}

export default ImageForm;