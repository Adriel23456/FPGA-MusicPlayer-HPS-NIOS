// ============================================================
// Module 1: 1Hz pulse generator from 50MHz clock
// ============================================================
// FREEZES count when !en (pause) so the fractional-second progress is
// preserved across pause/resume. Only rst clears the count. This stops the
// timer from losing up to ~1 s of progress on every pause.
module extra_ClockDivider #(parameter int unsigned CLK_FREQ = 50_000_000) (
    input  logic clk,
    input  logic rst,
    input  logic en,
    output logic pulse_1hz
);
    logic [$clog2(CLK_FREQ)-1:0] count;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count     <= '0;
            pulse_1hz <= 0;
        end else if (!en) begin          // PAUSE: freeze, do NOT reset
            count     <= count;          // hold accumulated fraction
            pulse_1hz <= 0;              // no tick while paused
        end else if (count == CLK_FREQ - 1) begin
            count     <= '0;
            pulse_1hz <= 1;
        end else begin
            count     <= count + 1;
            pulse_1hz <= 0;
        end
    end
endmodule