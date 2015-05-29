// Calls all the scripts for the final presentation.
// Execute these lines one by one at the appropriate times

// Geoff's settings
(
~touchIP = "10.150.97.142";
~finchPresets = ["blank.yaml", "oboe_c.yaml", "b-flat.yaml", "blips_1.yaml"];
~toneClusterPlayer = 0;
~toneClusterTransp = 1.5 * [-17, -3, 0, -3];
)

// Kyler's settings
(
~touchIP = "10.150.97.142";
~finchPresets = ["blank.yaml", "blips_2.yaml"];
~toneClusterPlayer = 1;
~toneClusterTransp = [-29, -6, -8, -7];
)

// Boot up the server
(
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 4;
s.boot;
s.meter;
)

// Set up
(
"finchesizer.scd".loadRelative;
"final_synths.scd".loadRelative; // Load non-finchesizer synths
"blip.scd".loadRelative; // Prepare markov chain piece w/ ringing noise
"develop.scd".loadRelative; // Markov chain 2
"tone_clusters.scd".loadRelative;
)



// If iPad doesn't work and it needs to be run with code:

// Run the markov chain piece that starts with LF square noise,
// and moves towards pitched stuff that sounds like tapping on strings.
// "blip.scd"
// Eval these lines to change scaler values and trigger steps manually:
// (it'll be easier to use the TouchOSC GUI)
~blipScaler = 0.1;
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

// Load the synths for the final markov tone cluster section
