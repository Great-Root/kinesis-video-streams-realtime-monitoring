import React from 'react';

import { Button, CheckboxField, Heading, Radio, RadioGroupField, Text, TextField } from '@aws-amplify/ui-react'

class ControlsForm extends React.Component  {

  constructor(props) {
    super(props)

    this.state = {
      region: 'us-east-1',
      channelName: 'test-channel',
      sendVideo: true,
      sendAudio: true,
      openDataChannel: false,
      resolution: 'fullscreen',
      natTraversalEnabled: true,
      forceTURN: false,
      natTraversalDisabled: false,
      useTrickleICE: true,
    }

    this.handleInputChange = this.handleInputChange.bind(this)
    this.startMaster = this.startMaster.bind(this)
    this.startViewer = this.startViewer.bind(this)
  }

  handleInputChange(event) {
    const target = event.target
    const value = target.type === 'checkbox' ? target.checked : target.value
    const name = target.name

    console.log(`Handling input change; name=${name} value=${value}`)

    this.setState({
      [name]: value
    })
  }

  startMaster(event) {
    event.preventDefault()

    if(this.state.channelName === '' || !this.state.channelName){
      alert('Channel Name is required')
      return
    }

    this.props.startMasterHandler(this.state)
  }

  startViewer(event) {
    event.preventDefault()

    if(this.state.channelName === '' || !this.state.channelName){
      alert('Channel Name is required')
      return
    }

    this.props.startViewerHandler(this.state)
  }

  render() {
    return (
      <form>
          <Heading level={3}>KVS Client Config</Heading>
          <TextField 
            placeholder="Enter a region code (i.e. us-east-1)" 
            name="region" 
            value={this.state.region}
            onChange={this.handleInputChange}
          />          
          <Heading level={3}>Signaling Channel</Heading>
          <TextField 
            placeholder="Signaling Channel Name"
            name="channelName" 
            value={this.state.channelName}
            onChange={this.handleInputChange}
          />

          <Heading level={3}>Tracks</Heading>
          <Text>Control which media types are transmitted to the remote peer.</Text>
          <CheckboxField
            label="Send Video"
            name="sendVideo"
            checked={this.state.sendVideo}
            onChange={this.handleInputChange}
          />
          <CheckboxField
            label="Send Audio"
            name="sendAudio"
            checked={this.state.sendAudio}
            onChange={this.handleInputChange}
          />
          <CheckboxField
            label="Open DataChannel"
            name="openDataChannel"
            checked={this.state.dataChannel}
            onChange={this.handleInputChange}
          />

          <Heading level={3}>Video Resolution</Heading>
          <Text>Set the desired video resolution and aspect ratio.</Text>
          <RadioGroupField name="resolution" value={this.state.resolution} onChange={this.handleInputChange}>
            <Radio value="widescreen">1280x720 <small>(16:9 widescreen)</small></Radio>
            <Radio value="fullscreen">640x480 <small>(4:3 fullscreen)</small></Radio>
          </RadioGroupField>

          <Heading level={3}>NAT Traversal</Heading>
          <Text>Control settings for ICE candidate generation.</Text>
          <CheckboxField
            label="STUN/TURN"
            name="natTraversal"
            value="natTraversalEnabled"
            checked={this.state.natTraversalEnabled}
            onChange={this.handleInputChange}
          />
          <CheckboxField
            label="TURN Only (force cloud relay)"
            name="natTraversal"
            value="forceTURN"
            checked={this.state.forceTURN}
            onChange={this.handleInputChange}
          />
          <CheckboxField
            label="Use trickle ICE (not supported by Alexa devices)"
            name="useTrickleICE"
            checked={this.state.useTrickleICE}
            onChange={this.handleInputChange}
          />
          <CheckboxField
            label="Disabled"
            name="natTraversal"
            value="natTraversalDisabled"
            checked={this.state.natTraversalDisabled}
            onChange={this.handleInputChange}
          />

          <Button onClick={this.startMaster}>Connect as Master</Button>
          <Button onClick={this.startViewer}>Connect as Viewer</Button>
      </form>
    )
  }
}

export default ControlsForm
