~cwd = thisProcess.nowExecutingPath.dirname +/+ "/samples/*";
~birds = SoundFile.collect(~cwd, s);

// should never get anywhere near this much
Server.local.options.numBuffers = ~birds.size * 2;


/*		0.1*Splay.ar(b.play(s, [\out, 0, \buf, buf]),
			1, // field width
			1, // level scaling
			0.0, // pan bias
			false // replayGain™
		);*/

Buffer.read(s, ~birds[0].path, 0, -1, { |buf|
	("playing buffer " + buf.bufnum).postln;
	{ PlayBuf.ar(2, buf, 1.0, doneAction: Done.freeSelf) }.play.onFree({
		("freeing buffer " + buf.bufnum).postln;
		buf.free;
	});
})


SynthDef("birb", { arg out, buf;
				var sample = PlayBuf.ar(
					2,
					buf,
					BufRateScale.kr(buf),
					doneAction: Done.freeSelf
				);
				var splayed = Splay.ar(
					sample,
					1,
					0.7,
					0.0,
					true
				);
				var verbed = 0.33 * GVerb.ar(
					splayed,
					100, // roomsize
					5, // revtime
					SinOsc.kr(0.2,0,0.1,0.5),
					0.7,
					20,
					3 // dry mix
				) * EnvGen.kr(Env.sine(BufDur.kr(buf)));
samp
				// Once *all* channels have been silent for 1 second, free
/*				FreeSelf.kr(
					DetectSilence.ar(splayed + Impulse.ar(0), 0.00001, 10000).product
				);*/
				Out.ar(out, verbed);
}).add;


r = Routine({
    var delta;
    "r -> ".postln;
    loop {
		var num = ~birds.size.rand;
		var bird = ~birds[num];
		("SAMPLE: " + bird.path).postln;
		Buffer.read(s, bird.path, 0, -1, { |buf|
			("playing buffer " + buf.bufnum).postln;
			x = Synth("birb", [ 0, buf ]);
			x.onFree(
				("freeing bufnum" + buf.bufnum).postln;
				buf.free
			);
			// free 5s after buffer end to allow for reverb tail
			// would prefer to do this with Done.kr(x)... but no idea how to run a Function from that?
/*			{
				("deallocating buffer " + buf.bufnum).postln;
				buf.free;
			}.defer(buf.duration + 120);*/
		});
		"Bird duration ".post; bird.duration.postln;
		delta = rrand(bird.duration * 0.5, bird.duration * 1.2);
		"Will wait ".post; delta.postln;
		delta.yield;
    }
});


SystemClock.sched(0, r);

{
	//var pulsed = Pulse.ar(116, SinOsc.kr(0.4, 0, 0.2, 0.5));
	var noise = PinkNoise.ar(0.7);
	var filtered = LPF.ar(noise, SinOsc.kr(24, 0, 10, 110));
	1.5*Splay.ar(filtered);
}.play

r.next;
r.stop;

Server.default.record;
Server.default.stopRecording;


SynthDef("detectSilence-help", { arg out;
    var z;
    z = SinOsc.ar(Rand(400, 700), 0, LFDNoise3.kr(8).max(0)).softclip * 0.3;
  //  DetectSilence.ar(z, doneAction: Done.freeSelf);
    Out.ar(out, z);
}).add;


Synth("detectSilence-help").onFree({
	"FREE".postln;
});
Synth("detectSilence-help");
Synth("detectSilence-help");

(
Task({
    loop({
        Synth("detectSilence-help");
        [0.5, 1].choose.wait;
    })
}).play;
)
