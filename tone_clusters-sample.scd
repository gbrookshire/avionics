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
var nodeVals, voiceArr, markovArr, bufferDict, playRates;
var makeGoFunc;
var wobbleDepth, wobbleRate, ampModDepth, ampModRate;
var sourceBus, fxBus, sourceGrp, fxGrp;
var crushSynth, verbSynth;
var transp;
var currDir = thisProcess.nowExecutingPath.dirname;

wobbleDepth = 0;
wobbleRate = 0;


// Function to make a go function for a markov chain
// takes a name of a voice.
makeGoFunc = {|voice, playbackRate|
	{|note|
		Synth(\playBuf,
			[
				bufnum: bufferDict[voice][note].bufnum,
				rate: playbackRate,
				wobbleDepth: wobbleDepth,
				wobbleRate: wobbleRate,
				ampModDepth: ampModDepth,
				ampModRate: ampModRate,
				out: sourceBus
			],
			sourceGrp
		);
		(voice + note).postln;
	};
};

nodeVals = (0..12); // Chromatic tones
voiceArr = ["crotale", "crotale", "crotale", "crotale"];

transp = {|x| (2 ** (x / 12))};
playRates = ~toneClusterTransp.collect({|x| 1/2 * transp.(x)});

// Make the Markov models
// Load transition matrices
// Make OSC responders for each model
markovArr = voiceArr.collect({arg voice, ind;
	var mrkv, oscAddr, pth, nMat;
	pth = currDir ++ "/tone_clusters/";
	oscAddr = '/4/push' ++ (ind + 1);
	nMat = (~toneClusterPlayer * 4) + ind + 1;
	nMat.postln;
	mrkv = MarkovSeq(makeGoFunc.(voice, playRates[ind]), nodeVals);
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
		wobbleDepth = (msg[1] * 0.1) + 0.0005;
	},
	'/4/fader1'
);
OSCdef.new(
	\markov3_wobble_rate_resp,
	{|msg, time, addr, port|
		wobbleRate = ((msg[1] + 0.05) ** 2) * 200;
	},
	'/4/fader2'
);
OSCdef.new(
	\markov3_amp_depth_resp,
	{|msg, time, addr, port|
		ampModDepth = (msg[1] ** 2);
	},
	'/4/fader3'
);
OSCdef.new(
	\markov3_amp_rate_resp,
	{|msg, time, addr, port|
		ampModRate = (msg[1] ** 2) * 100;
	},
	'/4/fader4'
);


// Load the samples into a buffer
// Dict of dicts -- dict for each voice, holds notes
// Notes indexed by 0
bufferDict = Dictionary.new;
voiceArr.do({arg voice, voiceInd;
	var fileStem = currDir++'/samples/'++voice++'/';
	bufferDict.put(
		voice,
		Array.fill(13, {|i| Buffer.read(s, fileStem++i++'.wav')})
	);
});


// Create the effect groups
sourceBus = Bus.audio(s, 2);
fxBus = Bus.audio(s, 2);

sourceGrp = Group.new;
fxGrp = Group.after(sourceGrp);

verbSynth = Synth.new(
	\mc3verb,
	[in:sourceBus, out:0, mix:0.3, room:0.2],
	fxGrp);

