/*
NOTE: this needs to be in:

- Linux: ~/.config/SuperCollider/startup.scd,
- macOS: ~/Library/Application Support/SuperCollider/startup.scd
- windows: ~/AppData/Local/SuperCollider/startup.scd

*/

Server.local.options
//.device("ASIO : Dante Virtual Soundcard")
.numOutputBusChannels_(36)
.numInputBusChannels(2)
.numAudioBusChannels_(2048)
.blockSize_(512)
.numWireBufs_(4096)
.memSize_(32*(2**16) - 1) // max size that boots successfully
.sampleRate_(48000);

"set server options".postln;
