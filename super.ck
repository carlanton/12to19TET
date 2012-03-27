/**
	TODO:
	
	* Möjlighet att välja tonart!

*/

Gain output => JCRev reverb => dac;
0.2 => output.gain; 
0.03 => reverb.mix;

20::ms => dur release_time;


144 => int NOTE_ON;
128 => int NOTE_OFF;

int notes[128];

false => int mode19;
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

		if (action == NOTE_ON) {	
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
			if (kb.getchar() == 32) { // Space
				!mode19 => mode19;
				<<< mode19 ? "Mode: 19 TET" : "Mode: 12 TET" >>>;
			}
		}
	}
}



fun float f(int n) {
	float freq;

	if (!mode19) {
		Std.mtof(n) => freq;
	} else {

		[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map[];
		n / 12 => int octave;
		map[n % 12] => n;

		// 2^(1/19) = 1.03715504
		Math.pow(2.0,octave - 3) * 65.4064 * Math.pow(1.03715504, n) => freq;
	}

	return freq;
}

fun void voice(int note, int velocity) {
	TriOsc voc => ADSR e => output; 
	velocity / 128.0 => voc.gain;
	f(note) => voc.freq;

	e.sustainLevel(.7);
	e.releaseTime(release_time);
	
	while (notes[note]) {
		midi_in => now;
	}

    e.keyOff();
    release_time => now;
}
