# Upload the following *passed* Verilog modules, sourced from (Ed Lesson task):

* top_level                        (Lesson 1: 3.3 Top-Level Modules II)
* timer                            (Lesson 1: 5.7 Timer Module)
* debounce                         (Lesson 2: 1.1 Debouncing Input)
* rng                              (Lesson 2: 1.4 Linear Feedback Shift Register)
* display, seven_seg.              (Lesson 2: 3.4 Double Dabble FSM)
* reaction_time_fsm                (Lesson 2: 3.5 Reaction Time FSM)

# Change the parameters in `debounce` and `timer` in the `top_level` instantiations
#     such that they count 20 cycles to a millisecond.
#     E.g. `debounce #(.DELAY_COUNTS(1)) u_debounce` etc...

# Make sure to invert KEY[0] in top-level somewhere as it is active-low on the DE2-115.

# Click "Mark" once all modules have been uploaded.
