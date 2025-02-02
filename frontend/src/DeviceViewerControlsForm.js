import React from 'react';

import { Button, CheckboxField, Divider, Heading, Radio, RadioGroupField, Text, TextField } from '@aws-amplify/ui-react'

class ControlsForm extends React.Component  {

  constructor(props) {
    super(props)

    this.state = {
      region: 'us-east-1',
      channelName: 'test-channel',
      sendVideo: false,
      sendAudio: false,
      openDataChannel: false,
      resolution: 'fullscreen',
      natTraversal: 'natTraversalEnabled',      
      useTrickleICE: true,
    }

    this.handleInputChange = this.handleInputChange.bind(this)
    this.startViewer = this.startViewer.bind(this)
    this.stopViewer = this.stopViewer.bind(this)
  }

  handleInputChange(event) {
    const target = event.target
    const value = target.type === 'checkbox' ? target.checked : target.value
    const name = target.name

    // console.log(`Handling input change; name=${name} value=${value}`)

    this.setState({
      [name]: value
    })
  }

  startViewer(event) {
    event.preventDefault()

    if(this.state.channelName === '' || !this.state.channelName){
      alert('Channel Name is required')
      return
    }

    this.props.startViewerHandler(this.state)
    this.setState({connected: true}) 
  }

  stopViewer(){
    this.props.stopViewerHandler(this.state)
    this.setState({connected: false}) 
  }

  render() {
    const isConnectedToDeviceVideoStream = this.state.connected
    let button;
    if(isConnectedToDeviceVideoStream){
      button = <Button className="controls-button" onClick={this.stopViewer}>Stop Viewer</Button> 
    }else{
      button = <Button className="controls-button" onClick={this.startViewer}>Connect as Viewer</Button>;
    }

    return (
      <form>
        <Heading level={3}>KVS Client Config</Heading>
        <TextField 
          placeholder="Enter a region code (i.e. us-east-1)" 
          name="region" 
          value={this.state.region}
          onChange={this.handleInputChange}
        />          
        <Heading level={3} className="controls-form-header">Signaling Channel</Heading>
        <TextField 
          placeholder="Signaling Channel Name"
          name="channelName" 
          value={this.state.channelName}
          onChange={this.handleInputChange}
        />

        <Heading level={3} className="controls-form-header">NAT Traversal</Heading>
        <Text>Control settings for ICE candidate generation.</Text>
        <RadioGroupField name="natTraversal" value={this.state.natTraversal} onChange={this.handleInputChange}>
          <Radio value="natTraversalEnabled">STUN/TURN</Radio>
          <Radio value="forceTURN">TURN Only (force cloud relay)</Radio>
          <Radio value="natTraversalDisabled">Disabled</Radio>
        </RadioGroupField>        

        <CheckboxField
          label="Use trickle ICE (not supported by Alexa devices)"
          name="useTrickleICE"
          checked={this.state.useTrickleICE}
          onChange={this.handleInputChange}
        />

        <Divider style={{margin: '2em 0 1em 0'}} orientation="horizontal" />
        {button}
      </form>
    )
  }
}

export default ControlsForm
