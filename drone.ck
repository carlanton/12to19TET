Gain output => JCRev reverb => dac;
0.2 => output.gain; 
0.05 => reverb.mix;


//MIDI related global arrays and variables:
int notes[128]; //The noteon array


int controllers[8];


int mode19;
false => mode19;

spork~drone();
spork~keyEvent();
spork~midi_input();

//It's good to yield after sporking letting the shreds to initialize. (In this case it wouldn't be really necessary.)
me.yield();

//Run forever in the background and let the shreds handle everything
while(true) {
    second => now; 
}


fun void keyEvent() {
	KBHit kb;

	while (true) {
		kb => now;

		while (kb.more()) {
			if (kb.getchar() == 32) { // Space
				!mode19 => mode19;
				<<< "Mode 19: " +  mode19 >>>;
			}
		}
	}
}

fun void drone() {
	SinOsc xs[8];

	for (0 => int i; i < xs.cap(); i++) {
		0 => xs[i].gain;
		xs[i] => output;
	}
	
	while (true) {
		for (0 => int i; i < xs.cap(); i++) {
			if (controllers[i] < 0) {
				0 => xs[i].gain;
			} else {
				.4 => xs[i].gain;
				controllers[i] => f => xs[i].freq;
			}
		}
		1::ms=> now;
	}
}

fun int y(int x) {
	if (x < 2)
		return -1;
	else
		return (24*x)/127 + 48;
}

//This one sporks new oscillators at the pitches indicated by the midi.
fun void midi_input() {
	MidiIn min;
	//connect to port 0
	if( !min.open(2) ) { <<<"No midi","found on port 0">>>; me.exit(); }
	// print out device that was opened
	<<< "MIDI device:", min.num(), " -> ", min.name() >>>;

	MidiMsg msg;

	while(true){
		 // Use the MIDI Event from MidiIn
		min => now;
		while( min.recv(msg) ) {
//			<<< msg.data1,msg.data2,msg.data3,"MIDI Message">>>; //Print the message

			if (msg.data1 == 176 ) { // Midi controller
				msg.data3 => y => controllers[msg.data2 - 9];
				<<< y(msg.data3) >>>;
			}
			
		}
	}
}

// 2^(1/12) = 1.05946309436
// 2^(1/19) = 1.03715504


fun float f(int n) {
//	if (!mode19) {
//		return Std.mtof(n);
//	}

	[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map[];
	n / 12 => int octave;
	map[n % 12] => n;

	return (Math.pow(2.0,octave - 3)) * 65.4064 * Math.pow(1.03715504, n );
}
