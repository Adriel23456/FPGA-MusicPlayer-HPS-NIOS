`timescale 1ns/1ps

module tb_AudioBiquadFilter;
    logic clk;
    logic reset_reset_n;
    logic [1:0] filter_mode;
    logic sample_valid;
    logic signed [15:0] sample_left_in;
    logic signed [15:0] sample_right_in;
    logic sample_ready;
    logic sample_valid_out;
    logic signed [15:0] sample_left_out;
    logic signed [15:0] sample_right_out;

    AudioBiquadFilter dut (
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

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic drive_sample(
        input logic [1:0] mode,
        input logic signed [15:0] left_value,
        input logic signed [15:0] right_value
    );
        begin
            filter_mode = mode;
            sample_left_in = left_value;
            sample_right_in = right_value;
            sample_valid = 1'b1;
            @(posedge clk);
            sample_valid = 1'b0;
        end
    endtask

    initial begin
        reset_reset_n = 1'b0;
        filter_mode = 2'b00;
        sample_valid = 1'b0;
        sample_left_in = '0;
        sample_right_in = '0;

        repeat (3) @(posedge clk);
        reset_reset_n = 1'b1;
        @(posedge clk);

        drive_sample(2'b00, 16'sd1234, -16'sd4321);
        if (!sample_valid_out) $fatal(1, "bypass: missing valid output");
        if (sample_left_out !== 16'sd1234 || sample_right_out !== -16'sd4321) begin
            $fatal(1, "bypass: output mismatch");
        end

        drive_sample(2'b01, 16'sd16000, 16'sd16000);
        if (!sample_valid_out) $fatal(1, "lowpass: missing valid output");
        if (sample_left_out === 16'sd16000) $fatal(1, "lowpass: should not equal bypass on first sample");

        drive_sample(2'b01, 16'sd0, 16'sd0);
        if (!sample_valid_out) $fatal(1, "lowpass decay: missing valid output");
        if ($signed(sample_left_out) >= 16'sd16000) $fatal(1, "lowpass decay: output did not move toward zero");

        drive_sample(2'b10, 16'sd8000, -16'sd8000);
        if (!sample_valid_out) $fatal(1, "bandpass: missing valid output");

        drive_sample(2'b11, 16'sd5000, 16'sd5000);
        if (!sample_valid_out) $fatal(1, "eq: missing valid output");

        $display("AudioBiquadFilter TB passed");
        $finish;
    end
endmodule