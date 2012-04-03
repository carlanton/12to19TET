//
// Ljudinställningar
//
0.3     => float outputGain;

10::ms  => dur attackTime;
5::ms   => dur decayTime;
0.5     => float sustainRate;
20::ms  => dur releaseTime;

20      => int numberOfVoices;
0       => int key;

// Tonmappning
[0,1,3,4,6,8,9,11,12,14,15,17] @=> int map[];

["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"] @=> string names[];

// MIDI-kommandon
144 => int NOTE_ON;
128 => int NOTE_OFF;
192 => int CHANGE_PROGRAM;

// Output patch
Gain output => dac;
outputGain => output.gain; 

// Events
class NoteEvent extends Event {
	int note;
	float velocity;
}



NoteEvent noteOnEvent;
Event @ noteOffEvents[128];


for (0 => int i; i < numberOfVoices; i++) {
	spork ~ voice();
}

midiHandler();

fun void midiHandler() {
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

				note => noteOnEvent.note;
				velocity / 128.0 => noteOnEvent.velocity;
				noteOnEvent.signal();
				me.yield();
			
			} else if (action == NOTE_OFF) {

				if (noteOffEvents[note] != null) {
					noteOffEvents[note].broadcast();
				}
			}
		}
	}
}

/**
 *
 */
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

/**
 *
 */
fun void voice() {
	TriOsc voc => ADSR e;

	Event noteOffEvent;
	int note;
	
	while (true) {
		// Vänta på att ett noteOnEvent ska komma:
		noteOnEvent => now;
		noteOnEvent.note => note;
		noteOnEvent.velocity => voc.gain;
	
		// Uppdatera inställningarna för filtret
		e.set(attackTime,decayTime,sustainRate,releaseTime);
	
		// Beräkna frekvensen för tonen:
		freq(note) => voc.freq;

		// Koppla till output 
		e => output;
		
		e.keyOn();
		
		if (noteOffEvents[note] == null) {
			noteOffEvent @=> noteOffEvents[note];
			noteOffEvent => now;
			null @=> noteOffEvents[note];
		} else {
			noteOffEvents[note] => now;
		}

		e.keyOff();

		// Vänta till att tonen har ringt klart
		releaseTime => now;

		// Koppla bort ifrån output
		e =< output;
	}
}
