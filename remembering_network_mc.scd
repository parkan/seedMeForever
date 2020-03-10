/*
s.options
//.device("ASIO : Dante Virtual Soundcard")
.numOutputBusChannels_(4)
.numAudioBusChannels_(2048)
.blockSize_(512)
.numWireBufs_(4096)
.memSize_(32*(2**16) - 1) // Z
.sampleRate_(48000);
s.reboot;*/
/*
(
Quarks.gui;
Quarks.install("https://github.com/ambisonictoolkit/atk-sc3.git");
Quarks.install("https://github.com/florian-grond/SC-HOA");
Atk.createUserSupportDir;
Atk.openUserSupportDir;
)

(
// a synthdef browser
SynthDescLib.global.read;
SynthDescLib.global.browse;
)*/

~cwd = thisProcess.nowExecutingPath.dirname +/+ "/samples/*";
~birds = SoundFile.collect(~cwd, s);


SynthDef(\boid, {| out = 0, buf = 0 |
	var point = PlayBuf.ar(2, buf, BufRateScale.kr(buf), doneAction: Done.freeSelf) * EnvGen.kr(Env.sine(BufDur.kr(buf)));
	var panned = 0.10*PanAz.ar(
		numChans: 4,
		in: point,
		pos: rrand(0,2),
		level: 1.0,
		width: 2
	);
	Out.ar(out, panned);
}).add;

SynthDef(\bigverb, { arg outBus = 0, inBus;
    var input, verbed;
    input = In.ar(inBus, 4);
	// verbed = GVerb.ar(
	// 	input,
	// 	100, // roomsize
	// 	7, // revtime
	// 	SinOsc.kr(0.2,0,0.1,0.5),
	// 	0.7,
	// 	20,
	// 	3 // dry mix
	// );

	Out.ar(outBus, input);
}).add;

b = Bus.audio(s, 4);

x = Synth.new(\bigverb, [ \inBus, b ]);

r = Routine({
    var delta;
    loop {
		var num = ~birds.size.rand;
		var bird = ~birds[num];
		Buffer.read(s, bird.path, 0, -1, { |buf|
			Synth.before(x, \boid, [\out, b, \buf, buf]);
			// free 5s after buffer end to allow for reverb tail
			// would prefer to do this with Done.kr(x)... but no idea how to run a Function from that?
			{
				// "deallocating buffer".postln;
				buf.free;
			}.defer(buf.duration + 5);
		});

		// always play at least 1 second uninterrupted
		d = bird.duration.max(1);
		// for longer samples, we want to increase the likelihood that another sample will play during it (but never before sec 1)
		n = -1 * d.linlin(1, 120, 0, d - 1);
		"n: ".post; n.postln;
		// for shorter samples, it's better to wait (TODO: pick an lincurve that does this better)
		p = d.linlin(1, 30, d * 3, 0);
		"p: ".post; p.postln;
		delta = rrand(n, p);
		"will wait ".post; delta.post; "/ sample length: ".post; bird.duration.postln;
		(d + delta).yield;
    }
});

/*0.10*PanAz.ar(
	numChans: 39,
	in: verbed,
	pos: 1.7,
	level: 1.0,
	width: 3
);*/

r.next();


// begin bird loop
SystemClock.sched(0, r);

// background tone
{
	// pulsed is harsher, noise is chiller
	//var pulsed = Pulse.ar(116, SinOsc.kr(0.4, 0, 0.2, 0.5));
	var noise = PinkNoise.ar(0.7);
	var filtered = LPF.ar(noise, SinOsc.kr(24, 0, 10, 110));
	1.5*Splay.ar(filtered);
}.play

/* HELPER CONTROLS:
r.play;
r.stop;
r.next;
*/

// FIRST ORDER ONLY (DO NOT USE)

// ------------------------------------------------------------
// virtual microphone stereo decoder
//
// mono pink noise source
// omni encoder


// define encoder / decoder matrices
~encoder = FoaEncoderMatrix.newOmni
~decoder = FoaDecoderMatrix.newStereo


// inspect
~encoder.kind
~encoder.numChannels
~encoder.dirChannels

~decoder.kind
~decoder.numChannels
~decoder.dirChannels.raddeg

(
{
    var sig;// audio signal
    var angle, azim;            // angle and azimuth control


    // display encoder and decoder
    "Ambisonic encoding via % encoder".format(~encoder.kind).postln;
    "Ambisonic decoding via % decoder".format(~decoder.kind).postln;

    // angle ---> top         = push to plane wave
    //            bottom        = omni-directional
    angle = MouseY.kr(pi/2, 0);

    // azimuth -> hard left     = back
    //          centre     = centre
    //          hard right     = back
    azim = MouseX.kr(pi, -pi);


    // ------------------------------------------------------------
    // test sig
    sig = PinkNoise.ar;             // mono pink noise


    // ------------------------------------------------------------
    // encode
    sig = FoaEncode.ar(sig, ~encoder);

    // ------------------------------------------------------------
    // transform
    sig = FoaTransform.ar(sig, 'push', angle, azim);


    // ------------------------------------------------------------
    // decode (to stereo)
    FoaDecode.ar(sig, ~decoder);

}.scope;
)

// free kernel
~decoder.free


// THE GOOD SHIT (UP TO 5TH ORDER)
~order = 3;
~hoaNumChannels = (~order+1).pow(2);
s.scope(~hoaNumChannels, 2);

(
~hoaSignal = NodeProxy.new(s, \audio, ~hoaNumChannels);
~hoaSignal.source = {HOAEncoder.ar(~order, WhiteNoise.ar(1), pi* 0.25, pi* 0.25 )};
~hoaSignal.fadeTime = 1;
~hoaSignal.play(0, ~hoaNumChannels);
)

~inFormat = \ACN_N3D; // we want this
// try all three different out formats
~outFormat = \ACN_SN3D;
~outFormat = \ACN_N3D; // we want this
~outFormat = \FuMa;

~hoaSignal.source = {HOAConvert.ar(~order,  HOAEncoder.ar(~order, WhiteNoise.ar(1), pi* 0.25, pi* 0.25 ), ~inFormat, ~outFormat)};

{
HOAEncoder.ar(
	~order,
		PinkNoise.ar,
		MouseX.kr(-pi, pi), // az
		0, // elev
	0, // gain
	1, // spherical
	MouseY.kr(0, 1), // distance to source
	// speaker radius??
)
}.play



s.doWhenBooted{
	"loading ambisonics".postln;
	HOADecLebedev26.loadHrirFilters(s, "/Users/arkadiy/Documents/repos/ambitools/FIR/hrir/hrir_christophe_lebedev50");
	HOADecLebedev06.loadHrirFilters(s, "/Users/arkadiy/Documents/repos/ambitools/FIR/hrir/hrir_christophe_lebedev50");
	~order = 4;
	~hoaNumChannels = (~order+1).pow(2);

	HOAEncoder.ar(
			~order,
			WhiteNoise.ar,
			MouseX.kr(pi, -pi), MouseY.kr(-pi * 0.5, pi * 0.5)
	);

	s.sync;
	Ndef(\hoaSignal).fadeTime = 1;
	Ndef(\hoaSignal, {
		HOAEncoder.ar(
			~order,
			WhiteNoise.ar,
			MouseX.kr(pi, -pi), MouseY.kr(-pi * 0.5, pi * 0.5)
		)
	}).play;

	s.sync;

	Ndef(\decoder).fadeTime = 1;
	Ndef(\decoder, {
		var in = \in.ar(0!(~hoaNumChannels));
		in
	}).play;

	1.wait;
	Ndef(\hoaSignal).gui <>> Ndef(\decoder).gui; // watch the oscilloscope
};

// reboot server (in case it was booted already, this will trigger evaluation of the above-defined doWhenBooted function
s.reboot;
)
