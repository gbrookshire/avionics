/*
Separate Markov chains play chords together

2 ipads, each with different chains.
Buttons to trigger the chains.
A few sliders to mess with sound parameters.

Different chains on each ipad

*/

// Synth def
// SynthDef(\playBuf, {
// 	arg out=0, bufnum=0, rate=1, wobbleDepth=0, wobbleRate=1,
// 	ampModRate=50, ampModDepth=0;
//
// 	var scaledRate, player, env;
// 	scaledRate = rate *  BufRateScale.kr(bufnum);
// 	scaledRate = scaledRate * LFNoise0.kr(wobbleRate, wobbleDepth, 1);
// 	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
// 	player = player * LFNoise0.ar(ampModRate).range(1-ampModDepth, 1);
// 	Out.ar(out, Pan2.ar(player, LFNoise1.kr(0.1)))
// }).add;

//
// Dictionary of instruments.
//    Each of those holds a dictionary of samples
var nodeVals, markovArr, playRates;
var goFunc;
var pitchMod, formStrength, ampModDepth, ampModRate;
var sourceBus, fxBus, sourceGrp, fxGrp;
var crushSynth, verbSynth;
var transp;
var currDir = thisProcess.nowExecutingPath.dirname;

pitchMod = 0.0293;
formStrength = 1;
ampModDepth = 1;
ampModRate = 100;

// Function to make a go function for a markov chain
// takes a name of a voice.
goFunc = {|freq|
	Synth(\clusterTone,
		[
			freq: freq.midicps,
			decay: ~toneDecay,
			formStrength: formStrength,
			pitchMod: pitchMod,
			ampModDepth: ampModDepth,
			ampModRate: ampModRate,
			out: sourceBus
		],
		sourceGrp
	);
};

nodeVals = (0..12); // Chromatic tones

// Make the Markov models
// Load transition matrices
// Make OSC responders for each model
markovArr = 4.collect({arg ind;
	var mrkv, oscAddr, pth, nMat;
	oscAddr = '/4/push' ++ (ind + 1);
	pth = currDir ++ "/tone_clusters/";
	nMat = (~toneClusterPlayer * 4) + ind + 1;
	mrkv = MarkovSeq(goFunc, 72 + nodeVals + ~toneClusterTransp[ind]);
	mrkv.loadTransMat(pth ++ "tm" ++ nMat ++ ".csv");
	OSCdef.new('markov3_step' ++ ind ++ '_resp',
		{|msg, time, addr, port|
			if (msg[1] == 1)
			{mrkv.step;}
			{}
		},
		oscAddr
	);
	mrkv
});


// An OSC responder to change the sound and adjust transitions
OSCdef.new(
	\markov3_wobble_depth_resp,
	{|msg, time, addr, port|
		formStrength = ((1 - msg[1]) + 0.3) * (1/1.3);
	},
	'/4/fader1'
);
OSCdef.new(
	\markov3_wobble_rate_resp,
	{|msg, time, addr, port|
		pitchMod = 0.001 + (1 - msg[1]) * (1 - (2 ** ((0.5)/12)));
	},
	'/4/fader2'
);
OSCdef.new(
	\markov3_amp_depth_resp,
	{|msg, time, addr, port|
		ampModDepth = ((1 - msg[1]) ** 2);
	},
	'/4/fader3'
);
OSCdef.new(
	\markov3_amp_rate_resp,
	{|msg, time, addr, port|
		ampModRate = ((1 - msg[1]) ** 2) * 100;
	},
	'/4/fader4'
);


// Create the effect groups
sourceBus = Bus.audio(s, 2);
fxBus = Bus.audio(s, 2);

sourceGrp = Group.new;
fxGrp = Group.after(sourceGrp);

verbSynth = Synth.new(
	\mc3verb,
	[in:sourceBus, out:0, mix:0.5, room:0.9],
	fxGrp);

