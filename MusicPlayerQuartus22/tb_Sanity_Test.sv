// =============================================================
// tb_Sanity_Test.sv — DE1-SoC sanity test
// SW[9:0]  -> LEDR[9:0]      (direct passthrough)
// KEY[0]   -> async reset (active low)
// LEDR[9]  -> 1 Hz blink (overrides SW[9] when KEY[1] is pressed)
// HEX0     -> shows SW[3:0] in hex
// =============================================================
module tb_Sanity_Test (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,        // active-low push buttons
    input  logic [9:0]  SW,
    output logic [9:0]  LEDR,
    output logic [6:0]  HEX0
);

    // ---------------- Reset ----------------
    logic rst_n;
    assign rst_n = KEY[0];

    // ---------------- 1 Hz blink ----------------
    localparam int TICK = 50_000_000 / 2;   // toggle every 0.5 s
    logic [25:0] cnt;
    logic        blink;

    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            cnt   <= '0;
            blink <= 1'b0;
        end else if (cnt == TICK - 1) begin
            cnt   <= '0;
            blink <= ~blink;
        end else begin
            cnt   <= cnt + 1'b1;
        end
    end

    // ---------------- LED outputs ----------------
    assign LEDR[8:0] = SW[8:0];
    // KEY[1] pressed (low) -> show blink on LEDR[9], else show SW[9]
    assign LEDR[9]   = (~KEY[1]) ? blink : SW[9];

    // ---------------- 7-seg decoder (active low) ----------------
    always_comb begin
        unique case (SW[3:0])
            4'h0: HEX0 = 7'b1000000;
            4'h1: HEX0 = 7'b1111001;
            4'h2: HEX0 = 7'b0100100;
            4'h3: HEX0 = 7'b0110000;
            4'h4: HEX0 = 7'b0011001;
            4'h5: HEX0 = 7'b0010010;
            4'h6: HEX0 = 7'b0000010;
            4'h7: HEX0 = 7'b1111000;
            4'h8: HEX0 = 7'b0000000;
            4'h9: HEX0 = 7'b0010000;
            4'hA: HEX0 = 7'b0001000;
            4'hB: HEX0 = 7'b0000011;
            4'hC: HEX0 = 7'b1000110;
            4'hD: HEX0 = 7'b0100001;
            4'hE: HEX0 = 7'b0000110;
            4'hF: HEX0 = 7'b0001110;
        endcase
    end

endmodule