// FILE: Filter_Decoder.sv
module Filter_Decoder (
    input  logic [1:0] sw,
    output logic [6:0] seg_out
);
    logic [3:0] bcd;

    always_comb begin
        unique case (sw)
            2'b00: bcd = 4'h0;
            2'b01: bcd = 4'hA;
            2'b10: bcd = 4'hB;
            2'b11: bcd = 4'hC;
        endcase
    end

    extra_BCD_to_7Segment seg_inst (
        .bcdInput (bcd),
        .segOutput(seg_out)
    );
endmodule