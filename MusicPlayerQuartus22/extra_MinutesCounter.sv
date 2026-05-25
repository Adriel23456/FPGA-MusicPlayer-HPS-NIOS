// ============================================================
// Module 3: Minutes counter (00–59)
//           Increments when it receives a carry from seconds
// ============================================================
module extra_MinutesCounter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    input  logic       carry_in,
    output logic [3:0] min_units,
    output logic [3:0] min_tens
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            min_units <= 0;
            min_tens  <= 0;
        end else begin
            if (en && carry_in) begin
                if (min_tens == 5 && min_units == 9) begin
                    min_units <= 0;     // 59min → reset to 00
                    min_tens  <= 0;
                end else if (min_units == 9) begin
                    min_units <= 0;
                    min_tens  <= min_tens + 1;
                end else begin
                    min_units <= min_units + 1;
                end
            end
        end
    end
endmodule