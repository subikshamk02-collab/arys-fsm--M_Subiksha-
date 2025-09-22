//  Autonomous Theme Park Ride Safety FSM (DUT)
//==============================================================
`timescale 1ns/1ps

module ride_fsm #(
  parameter int DEBOUNCE_CYCLES = 3,
  parameter int PERSIST_CYCLES  = 5,
  parameter int SHUTDOWN_TIMEOUT= 20
)(
  input  logic clk,
  input  logic rst_n,
  input  logic vibration_raw,
  input  logic queue_raw,
  input  logic brake_raw,
  input  logic restraint_raw,
  input  logic mask_vibration,
  input  logic mask_queue,
  input  logic mask_brake,
  input  logic mask_restraint,
  output logic [1:0] state,
  output logic alarm,
  output logic [2:0] fault_code
);

  typedef enum logic [1:0] {S_NORMAL=2'd0,S_WARNING=2'd1,S_FAULT=2'd2,S_SHUTDOWN=2'd3} state_t;
  state_t cur_state, nxt_state;

  // Debounced signals and counters
  logic vibration_db, queue_db, brake_db, restraint_db;
  integer cnt_vib, cnt_queue, cnt_brake, cnt_rest;

  task automatic debounce(
    input  logic raw,
    inout  logic db,
    inout  integer cnt
  );
    if (raw==db) cnt = 0;
    else begin
      cnt++;
      if (cnt>=DEBOUNCE_CYCLES) begin
        db = raw;
        cnt=0;
      end
    end
  endtask

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vibration_db<=0; queue_db<=0; brake_db<=0; restraint_db<=0;
      cnt_vib=0; cnt_queue=0; cnt_brake=0; cnt_rest=0;
      cur_state<=S_NORMAL;
    end else begin
      debounce(vibration_raw,vibration_db,cnt_vib);
      debounce(queue_raw,queue_db,cnt_queue);
      debounce(brake_raw,brake_db,cnt_brake);
      debounce(restraint_raw,restraint_db,cnt_rest);
      cur_state<=nxt_state;
    end
  end

  // Masking
  logic vib,que,brk,res;
  always_comb begin
    vib = vibration_db & ~mask_vibration;
    que = queue_db & ~mask_queue;
    brk = brake_db & ~mask_brake;
    res = restraint_db & ~mask_restraint;
  end

  always_comb begin
    if (res)      fault_code=3'd1;
    else if (brk) fault_code=3'd2;
    else if (vib) fault_code=3'd3;
    else if (que) fault_code=3'd4;
    else          fault_code=3'd0;
  end

  logic any_flag = res|brk|vib|que;
  integer persist_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) persist_cnt<=0;
    else if (cur_state==S_WARNING || cur_state==S_FAULT) begin
      if (any_flag) persist_cnt<=persist_cnt+1;
      else persist_cnt<=0;
    end else if (cur_state==S_NORMAL && any_flag) persist_cnt<=1;
    else persist_cnt<=0;
  end

  always_comb begin
    nxt_state=cur_state;
    unique case(cur_state)
      S_NORMAL:  if(any_flag) nxt_state=S_WARNING;
      S_WARNING: begin
        if(res||brk) nxt_state=S_FAULT;
        else if(persist_cnt>=PERSIST_CYCLES) nxt_state=S_FAULT;
        else if(!any_flag) nxt_state=S_NORMAL;
      end
      S_FAULT: begin
        if(persist_cnt>=SHUTDOWN_TIMEOUT || res) nxt_state=S_SHUTDOWN;
        else if(!any_flag) nxt_state=S_WARNING;
      end
      S_SHUTDOWN: nxt_state=S_SHUTDOWN;
    endcase
  end

  assign state=cur_state;
  assign alarm=(cur_state!=S_NORMAL);

endmodule
