Gain output => dac;
0.5 => output.gain; 

20::ms => dur release_time;

//[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map12[]; 
[0,1,3,4,6,8,9,11,12,14,16,17] @=> int map[]; // Mellandom
//[0,-1,3,-1,6,8,-1,11,-1,14,-1,17] @=> int map[];

144 => int NOTE_ON;
128 => int NOTE_OFF;
192 => int PROGRAM;


// 128 = 2^6
// Todo gör om detta till 1 int (eller något som är 8bitar)
int notes[128];

["C"
,"Db"
,"D"
,"Eb"
,"E"
,"F"
,"Gb"
,"G"
,"Ab"
,"A"
,"Bb"
,"B"] @=> string key_names[];

0 => int key;

// Midi grejer
0 => int midi_port;

MidiIn midi_in;
if (!midi_in.open(midi_port)) {
	me.exit();
} else {
	<<< "Opened MIDI device", midi_in.num(), "(", midi_in.name(), ")" >>>;
}

spork ~ keyEvent();
MidiMsg midi_msg;

while (true) {
	midi_in => now;

	while (midi_in.recv(midi_msg)) {
		midi_msg.data1 => int action;
		midi_msg.data2 => int note;
		midi_msg.data3 => int velocity;

		if (action == PROGRAM) {
			note => key;

			if (key < 12) {
				<<< "Using 19TET with key", key_names[key] >>>;
			} else {
				<<< "Using 12TET" >>>;
			}
		}


		if (action == NOTE_ON) {
			<<< key_names[note % 12] >>>;
			//Send pitch and velocity information
			if (!notes[note]) 
				spork ~ voice(note, velocity);

			// Set note on
			true => notes[note];
		}

		if (action == NOTE_OFF) {
			// Set note off
			false => notes[note];
		}
	}
}

fun void keyEvent() {
	KBHit kb;

	while (true) {
		kb => now;

		while (kb.more()) {
			kb.getchar() => int c;
			
			if (c >= 48 && c <= 57) {
				c - 48 => key;
				<<< "Using 19TET with key", key >>>;
			}
		}
	}
}

fun float freq(int note) {
	float freq;

	if (key == 12) {
		Std.mtof(note) => freq;
	} else {
		
		note - key => note;

		if (map[note % 12] == -1) {
			<<< "undef tone", (note%12), "in key", key >>>;
			return 0.0;
		}

		note / 12 => int octave;
		map[note % 12] => int n;


		Std.mtof(key) * Math.pow(2, octave + n/19.0) => freq;
	}

	return freq;
}

fun void voice(int note, int velocity) {
	SinOsc voc => ADSR e => output; 
	
	e.set(
		10::ms, // Attack time
		5::ms, // Decay time	
		.5,    // Sustain rate
		release_time); // Release time

	velocity / 128.0 => voc.gain;
	freq(note) => voc.freq;

	e.keyOn();
	
	while (notes[note]) {
		midi_in => now;
	}

    e.keyOff();
    release_time => now;
}
