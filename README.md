# MIDI Panic

MIDI Panic module based on MICROCHIP PIC12C508 or 16F84. To build the firmware, checkout [GNU Pic Utilities](https://gputils.sourceforge.io/), then :

```
cd src && make
```

## Construction

The panic device can run as a standalone module :

<p align="center">
  <img src="figures/schema.svg" width="500"/>
</p>
Or be include in an existing device. Eg. a MIDI Thru-box: 
<p align="center">
  <img src="figures/interface.svg" width="500"/>
</p>

## About the 16F84A version

The 16F84A version require a 4MHz external oscillator. If you want run the device with internal oscillator (not recommanded), add the <code>USE_INTERNAL_OSC</code> flag in Makefile:

```
ASMFLAGS="-w1 -D HAVE_RUNNING_STATUS -D USE_INTERNAL_OSC"
```

The pinout for the 16F84A version is as follow:

```
S1       = pin 6  (PORTB-0)
S2       = pin 7  (PORTB-1)
S4       = pin 8  (PORTB-2)
MIDI IN  = pin 18 (PORTA-1)
MIDI OUT = pin 1  (PORTA-2) 
```

## Example of connection

<p align="center">
  <img src="figures/connexion.svg" width="600"/>
</p>

## Switchs configuration

* If no switch is active (S1 or S2), the panic device act as a passthrough device. 
* If S1 is active, the panic device send a ```Note Off``` message for each note (from 0 to 127). It take several seconds to complete.
* If S2 is active, the panic devise send a ```All Sounds Off``` message. Some old sound generators may not understand this mesage but it take less than 10ms to complete.
* S3 prevents unintentional actions on S1 or S2.
* If S4 is active (connect to ground), the Panic device use the ```Running Status``` to shorten ```Note Off``` messages. It as no effect with the ```All sounds Off``` message.
