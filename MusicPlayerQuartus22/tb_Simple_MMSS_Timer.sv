`timescale 1ns/1ps

module tb_Simple_MMSS_Timer;

    // ── DUT ports ────────────────────────────────────────────
    logic       clk;
    logic [1:0] timer_ctrl;
    logic [6:0] seg_min_tens;
    logic [6:0] seg_min_units;
    logic [6:0] seg_sec_tens;
    logic [6:0] seg_sec_units;

    // ── Instantiate DUT ──────────────────────────────────────
    MMSS_Timer #(.CLK_FREQ(10)) dut (   // 1 simulated second = 10 clock cycles
		 .clk          (clk),
		 .timer_ctrl         (timer_ctrl),
		 .seg_min_tens (seg_min_tens),
		 .seg_min_units(seg_min_units),
		 .seg_sec_tens (seg_sec_tens),
		 .seg_sec_units(seg_sec_units)
	 );

    // ── 50 MHz clock (period = 20 ns) ────────────────────────
    initial clk = 0;
    always #10 clk = ~clk;

    // ── Shorthand: one real second in simulation cycles ──────
    localparam ONE_SEC = 10;

    // ── Helper task: wait N seconds ──────────────────────────
    task wait_seconds(input int n);
        repeat (n * ONE_SEC + 2) @(posedge clk);
    endtask

    // ── Helper task: apply timer_ctrl for one clock then back to 00 ─
    task apply_ctrl(input logic [1:0] c);
        timer_ctrl = c;
        @(posedge clk);
        timer_ctrl = 2'b00;
    endtask

    // ── Helper: print current display values ─────────────────
    // We decode the internal BCD directly for readability
    task print_time(input string label);
        $display("[%0t ns] %s  =>  %0d%0d:%0d%0d",
            $time, label,
            dut.min_tens, dut.min_units,
            dut.sec_tens, dut.sec_units);
    endtask

    // ── Main test sequence ───────────────────────────────────
    initial begin
        timer_ctrl = 2'b00;

        // ------------------------------------------------
        // TEST 1: Reset – timer must stay at 00:00
        // ------------------------------------------------
        $display("=== TEST 1: Reset ===");
        apply_ctrl(2'b11);                  // reset
        repeat(5) @(posedge clk);
        print_time("After reset");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: timer not at 00:00 after reset");

        // ------------------------------------------------
        // TEST 2: timer_ctrl=00 – timer must stay at 00:00 (idle)
        // ------------------------------------------------
        $display("=== TEST 2: Do-nothing while stopped ===");
        timer_ctrl = 2'b00;
        wait_seconds(3);
        print_time("After 3s idle (should still be 00:00)");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: timer advanced while idle");

        // ------------------------------------------------
        // TEST 3: Resume – count 5 seconds
        // ------------------------------------------------
        $display("=== TEST 3: Resume and count 5 seconds ===");
        apply_ctrl(2'b01);                  // resume
        wait_seconds(5);
        print_time("After 5s running");
        assert (dut.sec_units == 5 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: expected 00:05");

        // ------------------------------------------------
        // TEST 4: Pause – time must freeze
        // ------------------------------------------------
        $display("=== TEST 4: Pause ===");
        apply_ctrl(2'b10);                  // pause
        wait_seconds(4);
        print_time("After 4s paused (should still be 00:05)");
        assert (dut.sec_units == 5 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: timer advanced while paused");

        // ------------------------------------------------
        // TEST 5: Resume after pause – count 5 more seconds
        // ------------------------------------------------
        $display("=== TEST 5: Resume after pause ===");
        apply_ctrl(2'b01);                  // resume
        wait_seconds(5);
        print_time("After 5 more seconds (should be 00:10)");
        assert (dut.sec_units == 0 && dut.sec_tens == 1 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: expected 00:10");

        // ------------------------------------------------
        // TEST 6: Seconds rollover 59 → 00, minute increments
        //         We are at 00:10, wait 50 more seconds → 01:00
        // ------------------------------------------------
        $display("=== TEST 6: Seconds rollover into minutes ===");
        wait_seconds(50);
        print_time("After 50 more seconds (should be 01:00)");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 1 && dut.min_tens == 0)
            else $fatal(1, "FAIL: expected 01:00");

        // ------------------------------------------------
        // TEST 7: Reset mid-run – must go back to 00:00
        // ------------------------------------------------
        $display("=== TEST 7: Reset mid-run ===");
        wait_seconds(30);                   // advance to 01:30
        print_time("At 01:30 before reset");
        apply_ctrl(2'b11);                  // reset
        repeat(5) @(posedge clk);
        print_time("Immediately after reset");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: timer not at 00:00 after mid-run reset");

        // Verify it stays at 00:00 without a resume
        wait_seconds(3);
        print_time("3s after reset without resume (should be 00:00)");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: timer ran after reset without resume");

        // ------------------------------------------------
        // TEST 8: Full rollover 59:59 → 00:00
        // Timer is at 00:00 stopped after TEST 7 reset.
        // Resume and count all the way up naturally.
        // ------------------------------------------------
        $display("=== TEST 8: Full rollover at 59:59 ===");
        apply_ctrl(2'b01);          // resume from 00:00
        wait_seconds(3599);         // natural count to 59:59
        print_time("At 59:59 (verify before rollover)");
        assert (dut.sec_units == 9 && dut.sec_tens == 5 &&
                dut.min_units == 9 && dut.min_tens == 5)
            else $fatal(1, "FAIL: expected 59:59 before rollover");

        wait_seconds(1);            // one more second → 00:00
        print_time("After 59:59 + 1s (should be 00:00)");
        assert (dut.sec_units == 0 && dut.sec_tens == 0 &&
                dut.min_units == 0 && dut.min_tens == 0)
            else $fatal(1, "FAIL: expected rollover to 00:00");

        // ------------------------------------------------
        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

    // ── Optional: waveform dump ──────────────────────────────
    initial begin
		$dumpfile("tb_Simple_MMSS_Timer.vcd");
		$dumpvars(0, tb_Simple_MMSS_Timer); // ← must match the module name above
	 end

endmodule