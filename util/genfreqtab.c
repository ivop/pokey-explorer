#include "stdio.h"
#include "math.h"

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

// Fn = F0 * a^n

#define F0 (440.0) // Hz
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
    int i;

    printf("n, equal_tempered, nearest_PAL, nearest_NTSC, "
           "PAL hex, NTSC hex\n");
    for (i=0; i<(NUMBER_OF_OCTAVES*12); i++) {
        equal_tempered_frequencies[i] = FORMULA(i+C1);
        printf("%i, %0.2f\n", i, equal_tempered_frequencies[i]);
    }

//    printf("test 440Hz: %f\n", FREQ_TO_VALUE(MAIN_CLOCK_PAL, 440));
//    printf("reverse test: %f\n", VALUE_TO_FREQ(MAIN_CLOCK_PAL, 2008));
}
