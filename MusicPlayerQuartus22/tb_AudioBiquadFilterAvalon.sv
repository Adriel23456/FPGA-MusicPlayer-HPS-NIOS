`timescale 1ns/1ps

module tb_AudioBiquadFilterAvalon;
    logic clk;
    logic reset_reset_n;
    logic [2:0] address;
    logic write;
    logic read;
    logic chipselect;
    logic [31:0] writedata;
    logic [31:0] readdata;
    logic waitrequest;

    AudioBiquadFilterAvalon dut (
        .clk         (clk),
        .reset_reset_n(reset_reset_n),
        .address     (address),
        .write       (write),
        .read        (read),
        .chipselect  (chipselect),
        .writedata   (writedata),
        .readdata    (readdata),
        .waitrequest  (waitrequest)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic mm_write(input logic [2:0] addr, input logic [31:0] data);
        begin
            @(negedge clk);
            address = addr;
            writedata = data;
            chipselect = 1'b1;
            write = 1'b1;
            read = 1'b0;
            @(negedge clk);
            write = 1'b0;
            chipselect = 1'b0;
        end
    endtask

    task automatic mm_read(input logic [2:0] addr, output logic [31:0] data);
        begin
            @(negedge clk);
            address = addr;
            chipselect = 1'b1;
            write = 1'b0;
            read = 1'b1;
            @(negedge clk);
            data = readdata;
            read = 1'b0;
            chipselect = 1'b0;
        end
    endtask

    initial begin
        reset_reset_n = 1'b0;
        address = '0;
        write = 1'b0;
        read = 1'b0;
        chipselect = 1'b0;
        writedata = '0;

        repeat (3) @(posedge clk);
        reset_reset_n = 1'b1;

        mm_write(3'd0, 32'd0);
        mm_write(3'd1, 32'sd1234);
        mm_write(3'd2, -32'sd1234);
        mm_write(3'd3, 32'd1);

        logic [31:0] status;
        mm_read(3'd3, status);
        if (status[0] !== 1'b0) $fatal(1, "busy should clear after processing");

        logic [31:0] left_out;
        logic [31:0] right_out;
        mm_read(3'd4, left_out);
        mm_read(3'd5, right_out);

        $display("Avalon wrapper outputs L=%0d R=%0d", $signed(left_out[15:0]), $signed(right_out[15:0]));
        $finish;
    end
endmodule