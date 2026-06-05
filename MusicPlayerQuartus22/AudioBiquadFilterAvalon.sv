module AudioBiquadFilterAvalon #(
    parameter int DATA_WIDTH = 16,
    parameter int COEF_WIDTH = 18,
    parameter int COEF_FRAC = 14
) (
    input  logic clk,
    input  logic reset_reset_n,

    input  logic [2:0] address,
    input  logic write,
    input  logic read,
    input  logic chipselect,
    input  logic [31:0] writedata,
    output logic [31:0] readdata,

    output logic waitrequest
);
    logic [1:0] filter_mode;
    logic sample_valid;
    logic signed [DATA_WIDTH-1:0] sample_left_in;
    logic signed [DATA_WIDTH-1:0] sample_right_in;
    logic sample_ready;
    logic sample_valid_out;
    logic signed [DATA_WIDTH-1:0] sample_left_out;
    logic signed [DATA_WIDTH-1:0] sample_right_out;

    logic busy;

    AudioBiquadFilter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEF_WIDTH(COEF_WIDTH),
        .COEF_FRAC(COEF_FRAC)
    ) core (
        .clk              (clk),
        .reset_reset_n    (reset_reset_n),
        .filter_mode      (filter_mode),
        .sample_valid     (sample_valid),
        .sample_left_in   (sample_left_in),
        .sample_right_in  (sample_right_in),
        .sample_ready     (sample_ready),
        .sample_valid_out (sample_valid_out),
        .sample_left_out  (sample_left_out),
        .sample_right_out (sample_right_out)
    );

    assign waitrequest = 1'b0;

    always_ff @(posedge clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            filter_mode     <= 2'b00;
            sample_valid     <= 1'b0;
            sample_left_in   <= '0;
            sample_right_in  <= '0;
            busy             <= 1'b0;
            readdata         <= '0;
        end else begin
            sample_valid <= 1'b0;

            if (chipselect && write) begin
                unique case (address)
                    3'd0: filter_mode <= writedata[1:0];
                    3'd1: sample_left_in <= writedata[15:0];
                    3'd2: sample_right_in <= writedata[15:0];
                    3'd3: begin
                        busy <= 1'b1;
                        sample_valid <= writedata[0];
                    end
                    default: ;
                endcase
            end

            if (sample_valid_out) begin
                busy <= 1'b0;
            end

            if (chipselect && read) begin
                unique case (address)
                    3'd0: readdata <= {30'd0, filter_mode};
                    3'd1: readdata <= {{16{sample_left_in[15]}}, sample_left_in};
                    3'd2: readdata <= {{16{sample_right_in[15]}}, sample_right_in};
                    3'd3: readdata <= {30'd0, busy, sample_ready};
                    3'd4: readdata <= {{16{sample_left_out[15]}}, sample_left_out};
                    3'd5: readdata <= {{16{sample_right_out[15]}}, sample_right_out};
                    default: readdata <= '0;
                endcase
            end
        end
    end
endmodule