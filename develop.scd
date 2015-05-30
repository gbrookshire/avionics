var goFunc1, nodeVals1, mrkv1, final1;
var goFunc2, nodeVals2, mrkv2, final2;
var goFunc3, nodeVals3, mrkv3, final3;
var projectDir;
var tempo;

tempo = 1.1;
projectDir = thisProcess.nowExecutingPath.dirname;

~devScaler = 1; // Adjust this value to adjust the sounds

~devTimeFunc = {|jit, temp, divisor|
	// Returns a timing function, which returns a time difference
	// between this note and the following note.
	var fnc;
	fnc = {
		abs(rrand(1 - jit, 1 + jit)) * temp / divisor
	};
	fnc
};

// Functions for chain 1
goFunc1 = {|freq|
	Synth(\twang, [freq:freq.midicps,
		decay:((1 - ~devScaler) ** 2) + 0.15,
		mod_strength:(~devScaler * 10),
		// mod_decay:(~devScaler * 0.6),
		wobble: ~devScaler * 100,
	])
};
nodeVals1 = [0, 10, 5, 14, -5, 0, -10, -5] + 57 - (2 * 12);
final1 = [
	0,1,0,0,0,0,0,0,
	0,0,1,0,0,0,0,0,
	0,0,0,1,0,5,5,0,
	1,0,0,0,1,0,0,0,
	0,0,0,0,0,1,0,0,
	0,0,1,0,0,0,1,0,
	0,0,0,0,0,1,0,1,
	1,0,0,0,0,1,0,0
];


// Functions for chain 2
goFunc2 = {|freq|
	Synth(\sputter, [freq:freq.midicps,
		decay: ((1 - ~devScaler) ** 2) + 0.04,
		resonate: (1 - ~devScaler) ** 4,
		wobble: (~devScaler ** 1.5) * 10,
		amp: (~devScaler * 3) + 1
	])
};
nodeVals2 = [0, 5, 2, 11, -5, 9, 7] + 60;
final2 = [
	0,1,0,0,0,0,0,
	0,1,1,3,0,0,0,
	0,0,0,1,0,1,2,
	0,0,0,0,1,2,2,
	0,0,0,0,0,1,0,
	1,0,0,0,0,0,1,
	1,0,0,0,0,0,0,
];

goFunc3 = {|freq|
	Synth(\gendy, [freq:freq.midicps,
		decay: ((1 - ~devScaler)**2) + 0.025,
		ascale: (~devScaler ** 0.5) + 0.001,
		dscale: (~devScaler ** 0.5) + 0.001,
	])
};
// nodeVals3 = [0, 6, 2, 10, -2, 8, -4] + 53;
nodeVals3 = [0, 3, 10, 12, 7, -2, -5] + 57;
final3 = [
	0,1,0,0,1,0,1,
	0,0,1,0,0,0,0,
	0,0,0,1,1,0,1,
	0,0,0,0,1,0,0,
	1,0,1,0,0,1,0,
	0,0,0,0,0,0,1,
	1,0,1,0,0,0,0
];

mrkv1 = MarkovSeq(goFunc1, nodeVals1);
mrkv2 = MarkovSeq(goFunc2, nodeVals2);
mrkv3 = MarkovSeq(goFunc3, nodeVals3);
~markovArr = [mrkv1, mrkv2, mrkv3];

mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, 1.2, 3);
mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, 1.2, 4);
mrkv3.timing_func = ~devTimeFunc.(2.0 * ~devScaler, 1.2, 4);

mrkv1.transition_mat = Array2D.fromArray(
	nodeVals1.size,
	nodeVals1.size,
	final1);
mrkv2.transition_mat = Array2D.fromArray(
	nodeVals2.size,
	nodeVals2.size,
	final2);
mrkv3.transition_mat = Array2D.fromArray(
	nodeVals3.size,
	nodeVals3.size,
	final3);


// Start the chains
Task({
	s.sync; // wait for the server
}).play;

// A button in TouchOSC to turn the chains on or off
OSCdef.new(
	\markov2_run_resp,
	{|msg, time, addr, port|
		if(msg[1] == 1,
			{~markovArr.collect({arg chain; chain.run})},
			{~markovArr.collect({arg chain; chain.pause})}
		);
	},
	'/3/toggle1'
);


// A slider to change the sound.
OSCdef.new(
	\markov2_tone_resp,
	{|msg, time, addr, port|
		~devScaler = 0.99 - (msg[1]);
	},
	'/3/markov2_tone'
);

// A slider to change the timing
OSCdef.new(
	\markov2_timing_resp,
	{|msg, time, addr, port|
		var tempo = 0.15 + (4 * ((1 - msg[1]) ** 2));
		mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 3);
		mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 4);
		mrkv3.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 4);
	},
	'/3/markov2_timing'
);

