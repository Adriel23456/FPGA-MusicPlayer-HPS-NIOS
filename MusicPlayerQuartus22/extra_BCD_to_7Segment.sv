module extra_BCD_to_7Segment(
    input logic [3:0] bcdInput,        // 4 bits BCD input
    output logic [6:0] segOutput        // Output
);

    // ---------------- 7-seg decoder (active low) ----------------
    always_comb begin
        unique case (bcdInput)
            4'h0: segOutput = 7'b1000000;
            4'h1: segOutput = 7'b1111001;
            4'h2: segOutput = 7'b0100100;
            4'h3: segOutput = 7'b0110000;
            4'h4: segOutput = 7'b0011001;
            4'h5: segOutput = 7'b0010010;
            4'h6: segOutput = 7'b0000010;
            4'h7: segOutput = 7'b1111000;
            4'h8: segOutput = 7'b0000000;
            4'h9: segOutput = 7'b0010000;
            4'hA: segOutput = 7'b0001000;
            4'hB: segOutput = 7'b0000011;
            4'hC: segOutput = 7'b1000110;
            4'hD: segOutput = 7'b0100001;
            4'hE: segOutput = 7'b0000110;
            4'hF: segOutput = 7'b0001110;
				default: segOutput = 7'b1111111;
        endcase
    end
endmodule