s.options.memSize = 65536;
s.boot;

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
				0.25 * GVerb.ar(
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

		// always play at least 1 second uninterrupted
		d = bird.duration.max(1);
		// for longer samples, we want to increase the likelihood that another sample will play during it (but never before sec 1)
		n = -1 * d.linlin(1, 120, 0, d - 1);
		"n: ".post; n.postln;
		// for shorter samples, it's better to wait (TODO: pick an lincurve that does this better)
		p = d.linlin(1, 30, d * 3, 0);
		"p: ".post; p.postln;
		// delta = rrand(bird.duration * -0.5, bird.duration * 0.2).clip2(10.0 + rrand(-6.0,0.0));
		delta = rrand(n, p);
		"will wait ".post; delta.post; "/ sample length: ".post; bird.duration.postln;
		(d + delta).yield;
    }
});


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
