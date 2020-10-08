// ---------------------------------------------------------------------------
// Generate tuning tables -- by Ivo van Poorten (C)2020 - 0BSD
// output RFC4180 CSV table with header
// ---------------------------------------------------------------------------

#define TUNE_TO_A (440.0)   // floating point double in Hertz

// ---------------------------------------------------------------------------

#include "stdio.h"
#include "math.h"

// ---------------------------------------------------------------------------

#define NUMBER_OF_OCTAVES 9

// semitone offsets

#define C1  (-45)
#define C2  (-33)
#define C3  (-21)
#define C4  (-9)
#define C5  (3)
#define C6  (15)
#define C7  (27)
#define C8  (39)
#define C9  (53)
#define C10 (63)

// Atari XL main clocks

#define MAIN_CLOCK_PAL  1773447.0
#define MAIN_CLOCK_NTSC 1789790.0

// Well-tempered tuning
//
// Fn = F0 * a^n

#define F0 (TUNE_TO_A) // Hz
#define a_100cents (pow(2.0,(1.0/12.0)))

#define FORMULA(n) ((F0) * (pow(a_100cents,(n))))

// Pokey 16-bit value to frequency relation
//
// f = sysclock/(v+7)/2
//
// so
//
// v = sysclock/(2*f) - 7

#define FREQ_TO_VALUE(sysclock, freq) ((sysclock/(2*freq))-7)
#define VALUE_TO_FREQ(sysclock, value) (sysclock/(value+7)/2)

double equal_tempered_frequencies[NUMBER_OF_OCTAVES*12];

int main(int argc, char **argv) {
    int i, v_pal, v_ntsc;
    double e, f_pal, f_ntsc;

    printf("n, equal_tempered_frequency, PAL_hex, NTSC_hex, "
           "PAL_frequency, NTSC_frequency\n");

    for (i=0; i<(NUMBER_OF_OCTAVES*12); i++) {
        e = equal_tempered_frequencies[i] = FORMULA(i+C1);

        v_pal  = round(FREQ_TO_VALUE(MAIN_CLOCK_PAL,  e));
        v_ntsc = round(FREQ_TO_VALUE(MAIN_CLOCK_NTSC, e));

        f_pal  = VALUE_TO_FREQ(MAIN_CLOCK_PAL,  v_pal );
        f_ntsc = VALUE_TO_FREQ(MAIN_CLOCK_NTSC, v_ntsc);

        printf("%i, %0.2f, %04x, %04x, %0.2f, %0.2f\n",
                i, equal_tempered_frequencies[i],
                v_pal, v_ntsc,
                f_pal, f_ntsc);
    }
}
