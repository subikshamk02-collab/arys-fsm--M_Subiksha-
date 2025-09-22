// Testbench for Ride Safety FSM
//==============================================================
`timescale 1ns/1ps
module ride_fsm_tb;

  logic clk=0, rst_n=0;
  logic vibration_raw, queue_raw, brake_raw, restraint_raw;
  logic mask_vibration, mask_queue, mask_brake, mask_restraint;
  logic [1:0] state;
  logic alarm;
  logic [2:0] fault_code;

  // DUT instantiation
  ride_fsm dut(
    .clk(clk), .rst_n(rst_n),
    .vibration_raw(vibration_raw), .queue_raw(queue_raw),
    .brake_raw(brake_raw), .restraint_raw(restraint_raw),
    .mask_vibration(mask_vibration), .mask_queue(mask_queue),
    .mask_brake(mask_brake), .mask_restraint(mask_restraint),
    .state(state), .alarm(alarm), .fault_code(fault_code)
  );

  // Clock generation (10 ns period)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, ride_fsm_tb);
  end

  // Monitor
  always @(state) $display("T=%0t ns, State=%0d, Alarm=%0b, Fault=%0d", $time, state, alarm, fault_code);

  initial begin
    // Initialize
    vibration_raw=0; queue_raw=0; brake_raw=0; restraint_raw=0;
    mask_vibration=0; mask_queue=0; mask_brake=0; mask_restraint=0;

    // Reset pulse
    #15 rst_n=1;

    // --- NORMAL ---
    #100;

    // --- WARNING: sustained vibration ---
    vibration_raw=1; #200; vibration_raw=0; #50;

    // --- FAULT: brake issue ---
    brake_raw=1; #200; brake_raw=0; #100;

    // --- SHUTDOWN: restraint failure ---
    restraint_raw=1; #300;

    // Hold for viewing
    #400 $finish;
  end

endmodule
