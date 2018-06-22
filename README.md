Music compilation system based on tup
================================================================================

The code in this repository implements a system whereby a collection of uncompressed music (for example, in the [WAVE](https://en.wikipedia.org/wiki/WAV) format) may be compressed into a variety of codecs (for instance, [FLAC](https://xiph.org/flac/) and [MP3](https://en.wikipedia.org/wiki/MP3)) and tagged automatically. It is possible to choose the compression codecs, the encoders to use and the settings to apply to each encoder, and the process may be carried out in a parallel manner. This all happens thanks to the [tup build system](http://www.gittup.org/tup/index.html), which is also able to detect any updates to the source files, the tag files, the encoder settings or even the encoder programs themselves and to compress again whatever depended on the updated components.

**TL;DR**: This system compresses and tags your music library in a variety of codecs with the settings you specify, requires nothing but the command line encoders and detects it when they are updated. You input a WAVE collection and some tag files and get compressed libraries with tags and album art.


Sources
--------------------------------------------------------------------------------

###  Structure
The system handles collections structured after the [vibes](https://www.davidjsp.eu/vibes/index) rules. Refer to the specification for detailed information.

###  Format
The format of the music sources should be [WAVE](https://en.wikipedia.org/wiki/WAV), for it is the common denominator amongst the encoders which the system currently supports.


Supported encoders
--------------------------------------------------------------------------------

 *  flac (FLAC)
 *  lame (MP3)
 *  oggenc (Vorbis)


Profiles
--------------------------------------------------------------------------------

Besides the music sources themselves, the system requires a set of _profiles_, which specify how to compress the music sources. Among other things, a profile defines:

 *  the codec after which to compress the music sources;
 *  the encoder program to use to that end;
 *  the general settings to apply to said encoder program; and
 *  any specific settings concerning specific files.

Thus, it would be possible to have a profile for computers based on the FLAC format, another one for a portable player outputting small MP3 files and a third one for the car using Vorbis.

Profiles are expressed in a [tup.config](http://gittup.org/tup/manual.html#lbAK) file, which is inputted by the tup build system. Refer to the tup manual for a detailed explanation of its format.

###  Settings

####  General settings

General settings:

 *  `ENCODER`

####  Encoder-specific settings

#####  flac

 *  `FLAC_FLAGS`

#####  lame

 *  `LAME_FLAGS`

#####  vorbis
