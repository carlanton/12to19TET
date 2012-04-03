


/**
 * Sound settings
 */

0.5     => float output_gain;
10::ms  => dur attack_time;
5::ms   => dur decay_time;
0.5     => float sustain_rate;
20::ms  => dur release_time;

20      => int voices;

/**
 * Tone mapping (12 -> 19)
 */

//[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map12[]; 
[0,1,3,4,6,8,9,11,12,14,16,17] @=> int map[]; // Mellandom
//[0,-1,3,-1,6,8,-1,11,-1,14,-1,17] @=> int map[];

/**
 * Midi actions
 */

144 => int NOTE_ON;
128 => int NOTE_OFF;
192 => int CHANGE_PROGRAM;

/**
 * Main output patch
 */

Gain output => dac;
output_gain => output.gain; 


class NoteEvent extends Event {
	int note;
	int velocity;
}

// the event
NoteEvent on;

// array of ugen's handling each note
Event @ us[128];


["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#","A", "A#" ,"B"]
	@=> string names[];

0 => int key;

for (0 => int i; i < voices; i++)
	spork ~ voice();

MidiIn midi_input;

if (!midi_input.open(0)) {
	me.exit();
} else {
	<<<
		"Opened MIDI device",
		midi_input.num(),
		"(", midi_input.name(), ")"
	>>>;
}

MidiMsg midi_msg;

while (true) {
	midi_input => now;

	while (midi_input.recv(midi_msg)) {
		midi_msg.data1 => int action;
		midi_msg.data2 => int note;
		midi_msg.data3 => int velocity;

		if (action == CHANGE_PROGRAM) {
			note => key;

			if (key < 12) {
				<<< "Using 19TET with key", names[key] >>>;
			} else {
				<<< "Using 12TET" >>>;
			}
		
		} else if (action == NOTE_ON) {

			note => on.note;
			velocity => on.velocity;
			on.signal();
			me.yield();
		
		} else if (action == NOTE_OFF) {

			if (us[note] != null)
				us[note].broadcast();

		}
	}
}


fun float freq(int note) {
	float freq;

	if (key >= 12) {
		Std.mtof(note) => freq;
	} else {
		
		note - key => note;

		if (map[note % 12] == -1) {
			<<<
				"undefined tone", note % 12,
				"in key", key
			>>>;
			return 0.0;
		}

		note / 12 => int octave;
		map[note % 12] => int n;


		Std.mtof(key) * Math.pow(2, octave + n/19.0) => freq;
	}

	return freq;
}

fun void voice() {
	SinOsc voc => ADSR e;
	e.set(attack_time,decay_time,sustain_rate,release_time);

	Event off;
	int note;
	
	while (true) {
		on => now;
		on.note => note;

		e => output;

		on.velocity / 128.0 => voc.gain;
		freq(note) => voc.freq;
		e.keyOn();

		if (us[note] != null) {
			us[note] => now;
		} else {
			off @=> us[note];
			off => now;
			null @=> us[note];
		}

		e.keyOff();
		release_time => now;
		e =< output;
	}
}
