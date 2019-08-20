~cwd = thisProcess.nowExecutingPath.dirname +/+ "/samples/*";
~birds = SoundFile.collect(~cwd, s);


/*		0.1*Splay.ar(b.play(s, [\out, 0, \buf, buf]),
			1, // field width
			1, // level scaling
			0.0, // pan bias
			false // replayGain™
		);*/



r = Routine({
    var delta;
    loop {
		var num = ~birds.size.rand;
		var bird = ~birds[num];
		Buffer.read(s, bird.path, 0, -1, { |buf|
			x = { var splayed =
				Splay.ar(
					PlayBuf.ar(buf.numChannels,buf, BufRateScale.kr(buf), doneAction: Done.freeSelfAndPrev),
					1,
					0.7,
					0.0,
					true
				);
				0.33 * GVerb.ar(
					splayed,
					100, // roomsize
					5, // revtime
					SinOsc.kr(0.2,0,0.1,0.5),
					0.7,
					20,
					3 // dry mix
				) * EnvGen.kr(Env.sine(BufDur.kr(buf)));
			}.play;
			// free 5s after buffer end to allow for reverb tail
			// would prefer to do this with Done.kr(x)... but no idea how to run a Function from that?
			{
				// "deallocating buffer".postln;
				buf.free;
			}.defer(buf.duration + 5);
		});
		// "Bird duration? ".post; bird.duration.postln;
		delta = rrand(bird.duration * 0.5, bird.duration * 1.2);
		// "Will wait ".post; delta.postln;
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
