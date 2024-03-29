/**
	TODO:
	
	* Möjlighet att välja tonart!

*/

Gain output => dac;
0.5 => output.gain; 

10::ms => dur release_time;

//[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map[];
[0,1,3,4,6,8,9,11,12,14,16,17] @=> int map[];

144 => int NOTE_ON;
128 => int NOTE_OFF;

int notes[128];

true => int mode19;
0 => int transpose;


0 => int midi_port;

MidiIn midi_in;
if (!midi_in.open(midi_port)) {
	me.exit();
} else {
	<<< "Opened MIDI device", midi_in.num(), "(", midi_in.name(), ")" >>>;
}

spork ~ keyEvent();

-1 => int status;
-1 => int round;

[0,0,1,1,0] @=> int startModes[];

[0,8,5,-2,8] @=> int trans[];


fun void mode() {
	status++;
	if (status % 8 == 0) {
		round++;
		startModes[round] => mode19;
		trans[round] => transpose;

		<<< "New round:", round, "Start mode:", mode19, "Transpose:", transpose >>>;


	} else 	if (status % 4 == 0) {
		!mode19 => mode19;

		<<< "Mode:", mode19 >>>;
	}
}



MidiMsg midi_msg;


while (true) {
	midi_in => now;

	while (midi_in.recv(midi_msg)) {
		midi_msg.data1 => int action;
		midi_msg.data2 => int note;
		midi_msg.data3 => int velocity;

		if (action == NOTE_ON) {
			mode();

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
			
			if (c == 32) {
				!mode19 => mode19;
				<<< mode19 ? "Mode: 19 TET" : "Mode: 12 TET" >>>;
				break;
			} else if (c >= 48 && c <= 57) {
				c - 48 => transpose;
			}
		}
	}
}

fun float freq(int note) {
	float freq;

	if (!mode19) {
		Std.mtof(note + transpose) => freq;
	} else {
		note / 12 => int octave;
		map[note % 12] => int n;

		Std.mtof(transpose) * Math.pow(2, octave + n/19.0) => freq;
	}

//	if (mode19)
//		<<< 1200 * Math.log2(Std.mtof(note) / freq) + " cent" >>>;
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
