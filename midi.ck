Gain output => JCRev reverb => dac;
0.2 => output.gain; 
0.05 => reverb.mix;


//MIDI related global arrays and variables:
int notes[128]; //The noteon array

int mode19;
false => mode19;

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

//This one sporks new oscillators at the pitches indicated by the midi.
fun void midi_input() {
	MidiIn min;
	//connect to port 0
	if( !min.open(0) ) { <<<"No midi","found on port 0">>>; me.exit(); }
	// print out device that was opened
	<<< "MIDI device:", min.num(), " -> ", min.name() >>>;

	MidiMsg msg;

	while(true){
		 // Use the MIDI Event from MidiIn
		min => now;
		while( min.recv(msg) ) {
//			<<< msg.data1,msg.data2,msg.data3,"MIDI Message">>>; //Print the message
			
			if (msg.data1 == 144) {	
				msg.data2 => int the_pitch;
				spork~tri_osc_note( the_pitch,msg.data3/128.0 ); //Send pitch and velocity information
				true => notes[the_pitch]; //Set note on
			}
			
			if (msg.data1 == 128) {
				false => notes[msg.data2]; /*Set note off, notes[] is a global array that controls all the playing oscillators*/
			}
		}
	}
}

// 2^(1/12) = 1.05946309436
// 2^(1/19) = 1.03715504


fun float f(int n) {
	if (!mode19) {
		return Std.mtof(n);
	}

	[0,2,3,5,6,8,9,11,13,14,16,17] @=> int map[];
	n / 12 => int octave;
	map[n % 12] => n;

	return (Math.pow(2.0,octave - 3)) * 65.4064 * Math.pow(1.03715504, n );
}

//Simple triangle wave
fun void tri_osc_note(int pitch, float velocity) {
	f(pitch) => float note;	
	<<< pitch + ", "+ note >>>;	
	//ChucK doesn't have a global control rate. We can define any control rate we want. :) Smaller value here => nicer for the ears.
	1::ms => dur update_time;
	
	//How long of a release do we want to do
	0.2::second => dur falloff_time;
	
	//The exponential falloff coefficient
	Math.pow(0.01,update_time/falloff_time) => float k;

	//The oscillator
	//TriOsc tri => Gain g => output; 
	SinOsc voc => Gain g => output; 
	//velocity => voc.noteOn;
	velocity => g.gain;

	while (notes[pitch]) { //While the note is on.
		note => voc.freq;
		update_time => now;
	}

	now + falloff_time => time later;
	
	while (now < later) { //Note off, time to release
		//Apply pitch_bend and modulation
		//Decrease volume exponentially
		//After all the multiplications g.gain() will be down to 0.01
		g.gain()*k => g.gain;
		update_time => now;
	} 
}
