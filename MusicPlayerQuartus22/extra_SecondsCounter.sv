// ============================================================
// Module 2: Seconds counter (00–59), emits a one-cycle carry
//           when rolling over from 59 → 00
// ============================================================
module extra_SecondsCounter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    input  logic       pulse_1hz,
    output logic [3:0] sec_units,
    output logic [3:0] sec_tens,
    output logic       carry       // one-cycle pulse on rollover
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sec_units <= 0;
            sec_tens  <= 0;
            carry     <= 0;
        end else begin
            carry <= 0;             // default: no carry
            if (en && pulse_1hz) begin
                if (sec_tens == 5 && sec_units == 9) begin
                    sec_units <= 0;
                    sec_tens  <= 0;
                    carry     <= 1;
                end else if (sec_units == 9) begin
                    sec_units <= 0;
                    sec_tens  <= sec_tens + 1;
                end else begin
                    sec_units <= sec_units + 1;
                end
            end
        end
    end
endmodule