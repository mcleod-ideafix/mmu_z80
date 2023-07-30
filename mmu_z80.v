`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company:        ZX Projects
// Engineer:       Miguel Angel Rodriguez Jodar
// 
// Create Date:    23:00:07 07/30/2023 
// Design Name: 
// Module Name:    mmu_z80 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
// MMU module. (c)2023 Miguel Angel Rodriguez Jodar
//  from a description by Peter Wilson (to follow)
//
// Registers
// ---------
// 8x8bit registers for address translation
// A control register to enable/disable translation
// Control:
// --------
// CS: A chip-select line for writing to or reading from those registers
// R/W: signal to distinguish between read/write to one of the registers
// 4 control address bits to select the target for read/write operations
// 8 data lines for read/write to the control registers (the CPU data bus)
// RESET: on reset address translation is disabled
// Translation:
// ------------
// 3 input address lines for translation
// 8 output address lines
// - with translation enabled, the content of the addressed register
// - with translation disabled, the content input three address lines are transparently passed through to the 
// low order 3 output address lines, all other address lines output zero
// OE: When low the output 8 address lines are active, tri-state when inactive

module z80mmu (
  input wire rst_n,        // active low reset 
  input wire [3:0] raddr,  // register address
  input wire cs_n,         // MMU chip select 
  input wire rw,           // RW operation (R=1, W=0)
  input wire oe_n,         // address bus output enable
  inout wire [7:0] d,       // tristate data bus
  input wire [2:0] a_in_15to13,  // address lines 13 to 15 from CPU
  output reg [7:0] a_out_20to13  // address lines 13 to 20 to memory
);
  
  // 1-bit control register
  reg enablemmu = 1'b0;
    
  // 8 x 8 bit bank registers
  reg [7:0] rbank0, rbank1, rbank2, rbank3, rbank4, rbank5, rbank6, rbank7;
  initial begin
    rbank0 = 8'h00;
    rbank1 = 8'h00;
    rbank2 = 8'h00;
    rbank3 = 8'h00;
    rbank4 = 8'h00;
    rbank5 = 8'h00;
    rbank6 = 8'h00;
    rbank7 = 8'h00;
  end
  
  // MMU translation
  always @* begin
    if (oe_n == 1'b1)   // OE=1 tristates the output address bus
      a_out_20to13 = 8'hZZ;
    else if (enablemmu == 1'b0)   // else, if translation is disabled, pass thru original address bus
      a_out_20to13 = {5'b00000, a_in_15to13};
    else begin
      case (a_in_15to13)   // else, do translation     
        3'd0: a_out_20to13 = rbank0;  // for some reason, XST doesn't allow
        3'd1: a_out_20to13 = rbank1;  // me to use rbank[1_in_15to13] directly
        3'd2: a_out_20to13 = rbank2;  // as part of the sensitivity list
        3'd3: a_out_20to13 = rbank3;  // so I need to explicity test for its
        3'd4: a_out_20to13 = rbank4;  // value in a case/endcase mux
        3'd5: a_out_20to13 = rbank5;
        3'd6: a_out_20to13 = rbank6;
        3'd7: a_out_20to13 = rbank7;
        default: a_out_20to13 = 8'hFF;  // this default case would never happen IRL
      endcase
    end  
  end
  
  // Data bus management
  reg [7:0] dout;
  assign d = (cs_n == 1'b0 && rw == 1'b1)? dout : 8'hZZ;  // tristate controller
  always @* begin
    if (raddr[3] == 1'b1)         
      dout = {7'b0000000, enablemmu};   // output the contents of the MMU control register, or...
    else begin
      case (raddr[2:0])
        3'd0: dout = rbank0;          // outputs the contents of the currently addressed bank register
        3'd1: dout = rbank1;
        3'd2: dout = rbank2;
        3'd3: dout = rbank3;
        3'd4: dout = rbank4;
        3'd5: dout = rbank5;
        3'd6: dout = rbank6;
        3'd7: dout = rbank7;
      endcase
    end
  end
  
  // Register management
  wire clkr = (~cs_n & ~rw);
  always @(posedge clkr or negedge rst_n) begin
    if (rst_n == 1'b0) begin   // if reset is active, zero all registers
      rbank0    <= 8'h00;
      rbank1    <= 8'h00;
      rbank2    <= 8'h00;
      rbank3    <= 8'h00;
      rbank4    <= 8'h00;
      rbank5    <= 8'h00;
      rbank6    <= 8'h00;
      rbank7    <= 8'h00;
      enablemmu <= 1'b0;     
    end
    else if (raddr[3] == 1'b1)  // else, there is an active writting operation
      enablemmu <= d[0];   // if register address is >=8, then write to control register
    else begin
      case (raddr[2:0])
        3'd0: rbank0 <= d;  // else, write to one of register banks 0 to 7
        3'd1: rbank1 <= d;
        3'd2: rbank2 <= d;
        3'd3: rbank3 <= d;
        3'd4: rbank4 <= d;
        3'd5: rbank5 <= d;
        3'd6: rbank6 <= d;
        3'd7: rbank7 <= d;
      endcase
    end
  end
endmodule
