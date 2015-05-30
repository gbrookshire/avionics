// Calls all the scripts for the final presentation.
// Execute these lines one by one at the appropriate times

// Geoff's settings
(
~touchIP = "192.168.1.139";
~finchPresets = ["blank.yaml", "oboe_c.yaml", "b-flat.yaml", "blips_1.yaml"];
~toneClusterPlayer = 0;
~toneClusterTransp = [-17, -3, 0, -3];
)

// Kyler's settings
(
~touchIP = "10.150.97.142";
~finchPresets = ["blank.yaml", "beginning_withvolume.yaml",
	"low_sound.yaml", "blips_2.yaml", "lastsound.yaml"];
~toneClusterPlayer = 1;
~toneClusterTransp = [-29, -6, -8, -7];
)

// Boot up the server and load synth defs
(
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 4;
s.boot;
s.meter;
)

(
"markov_synth_defs.scd".loadRelative; // Load non-finchesizer synths
)

// Initialize the chains
(
"finchesizer.scd".loadRelative;
"blip.scd".loadRelative; // Markov I - Quantized noise w/ ringing filter
"develop.scd".loadRelative; // Markov II - inspired by finch vocal devo
"tone_clusters.scd".loadRelative; // Markov III -- Tone clusters
)



// If iPad doesn't work and it needs to be run with code, use this:



// Run the markov chain piece that starts with LF square noise,
// and moves towards pitched stuff that sounds like tapping on strings.
// "blip.scd"
// Eval these lines to change scaler values and trigger steps manually:
// (it'll be easier to use the TouchOSC GUI)
~blipScaler = 0.8;
~blipMarkov.step;

// Run the markov chain piece that is inspired by vocal development.
// These lines change the values (but use the GUI if possible).
~devScaler = 1; // Reduce to 0 for more pitched sounds
~markovArr.collect({arg chain; chain.run});
~markovArr.collect({arg chain; chain.pause});
(
var tempo = 1.0; // Smaller tempo means a more dense sound.
~markovArr.collect({arg chain;
	chain.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 3);
});
)