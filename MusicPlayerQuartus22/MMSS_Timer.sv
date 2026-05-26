// ============================================================
// Main Component: MM:SS Timer
//   Outputs: 4x 7-segment displays (active-low, uses your
//            existing extra_BCD_to_7Segment module)
// ============================================================
module MMSS_Timer #(parameter int unsigned CLK_FREQ = 50_000_000) (
    input  logic       clk,
    input  logic [1:0] timer_ctrl,
    output logic [6:0] seg_min_tens,
    output logic [6:0] seg_min_units,
    output logic [6:0] seg_sec_tens,
    output logic [6:0] seg_sec_units,
	 output logic [1:0] timer_status
);
    logic rst, en, pulse_1hz, sec_carry;
    logic [3:0] sec_units, sec_tens, min_units, min_tens;

    extra_TimerControlUnit ctrl_unit (
		 .clk,
		 .timer_ctrl,
		 .rst,
		 .en,
		 .timer_status
	 );

    extra_ClockDivider #(.CLK_FREQ(CLK_FREQ)) clk_div (
        .clk, .rst, .en,             // en passed so divider resets on pause
        .pulse_1hz
    );

    extra_SecondsCounter sec_cnt (
        .clk, .rst, .en, .pulse_1hz,
        .sec_units, .sec_tens, .carry(sec_carry)
    );

    extra_MinutesCounter min_cnt (
        .clk, .rst, .en, .carry_in(sec_carry),
        .min_units, .min_tens
    );

    extra_BCD_to_7Segment su (.bcdInput(sec_units), .segOutput(seg_sec_units));
    extra_BCD_to_7Segment st (.bcdInput(sec_tens),  .segOutput(seg_sec_tens));
    extra_BCD_to_7Segment mu (.bcdInput(min_units), .segOutput(seg_min_units));
    extra_BCD_to_7Segment mt (.bcdInput(min_tens),  .segOutput(seg_min_tens));
endmodule