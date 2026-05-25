// ============================================================
// Module 4: Control FSM
//
// INPUT COMMANDS (timer_ctrl)
//   timer_ctrl 2'b00 → do nothing  (maintain current state)
//   timer_ctrl 2'b01 → resume / run timer
//   timer_ctrl 2'b10 → pause timer
//   timer_ctrl 2'b11 → reset timer to 00:00
//
// OUTPUT STATUS (timer_status)
//   timer_status 2'b00 → nothing happening
//   timer_status 2'b01 → running
//   timer_status 2'b10 → paused
//   timer_status 2'b11 → reset state
//
// NOTE:
//   timer_ctrl represents CPU/user commands.
//   state represents the ACTUAL internal FSM state.
//   timer_status is a logical interpretation of the FSM.
// ============================================================
module extra_TimerControlUnit (
    input  logic       clk,
    input  logic [1:0] timer_ctrl,

    output logic       rst,
    output logic       en,

    // CPU-readable state
    output logic [1:0] timer_status
);

    typedef enum logic [1:0] {
        PAUSED     = 2'b00,
        RUNNING    = 2'b01,
        RESET_STATE = 2'b10
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        case (timer_ctrl)

            // Resume
            2'b01:
                state <= RUNNING;

            // Pause
            2'b10:
                state <= PAUSED;

            // Reset
            2'b11:
                state <= RESET_STATE;

            // Hold current state
            default:
                state <= state;

        endcase
    end

    // Outputs derived from state
    assign rst = (state == RESET_STATE);
    assign en  = (state == RUNNING);

    // Logical status exposed to CPU
    assign timer_status =
        (timer_ctrl == 2'b00) ? 2'b00 :   // nothing happening
        (state == RUNNING)  ? 2'b01 :
        (state == PAUSED)   ? 2'b10 :
                              2'b11;      // RESET_STATE

endmodule