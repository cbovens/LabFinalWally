// LFSR Collin Bovenschen Koby Goree

module cacheLFSR
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128) (
  input  logic                clk, 
  input  logic                reset,
  input  logic                FlushStage,
  input  logic                CacheEn,         // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [NUMWAYS-1:0]  HitWay,          // Which way is valid and matches PAdr's tag
  input  logic [NUMWAYS-1:0]  ValidWay,        // Which ways for a particular set are valid, ignores tag
  input  logic [SETLEN-1:0]   CacheSetData,    // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   CacheSetTag,     // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   PAdr,            // Physical address 
  input  logic                LRUWriteEn,      // Update the LRU state
  input  logic                SetValid,        // Set the dirty bit in the selected way and set
  input  logic                ClearValid,      // Clear the dirty bit in the selected way and set
  input  logic                InvalidateCache, // Clear all valid bits
  output logic [NUMWAYS-1:0]  VictimWay        // LRU selects a victim to evict
  );

   localparam LOGNUMWAYS = $clog2(NUMWAYS); //Will change in size depending on NUMWAYS param
   
   logic AllValid;
   logic RegEn;
   logic [NUMWAYS-1:0] FirstZero;
   logic [LOGNUMWAYS-1:0] FirstZeroWay, VictimWayEnc;
   logic [LOGNUMWAYS+1:0] d, q, val;

   assign AllValid = &ValidWay; //& ValidWay with itself returns a boolean value
   assign RegEn = ~FlushStage & LRUWriteEn;

   //"Seed" value
   assign val[0] = 1'b1;
   assign val[LOGNUMWAYS+1:1] = 0;
   
   priorityonehot #(NUMWAYS) FirstZeroEncoder(~ValidWay, FirstZero);
   binencoder #(NUMWAYS) FirstZeroWayEncoder(FirstZero, FirstZeroWay);
   mux2 #(LOGNUMWAYS) LSFRWayMuxEnc(FirstZeroWay, q[LOGNUMWAYS-1:0], AllValid, VictimWayEnc); //What is Curr[1:0]???
   decoder #(LOGNUMWAYS) DecoderMod(VictimWayEnc, VictimWay);

flopenl #(LOGNUMWAYS+2) LogicLFSR(clk, reset, LRUWriteEn, q, val, d); //+2 for first and last flop
assign q[LOGNUMWAYS:0] = d[LOGNUMWAYS+1:1];

//XOR poly logic on bit selection
//assign MSB using XOR primative polynomial logic creating pseudo-random behavior
if(NUMWAYS == 2)
  begin
    assign q[2] = d[2] ^ d[0]; //0x5  b-0101
  end
else if(NUMWAYS == 4)
  begin
    assign q[3] = d[3] ^ d[0]; //0x9  b-1001
  end
else if(NUMWAYS == 8)
  begin
    assign q[4] = d[4] ^ d[3] ^ d[2] ^ d[0]; //0x1D  b-0001_1101
  end
else if(NUMWAYS == 16)
  begin
    assign q[5] = d[5] ^ d[4] ^ d[2] ^ d[1]; //0x36  b-0011_0110
  end
else if(NUMWAYS == 32)
  begin
    assign q[6] = d[6] ^ d[5] ^ d[3] ^ d[0]; //0x69  b-0110_1001
  end
else if(NUMWAYS == 64)
  begin
    assign q[7] = d[7] ^ d[5] ^ d[2] ^ d[1]; //0xA6  b-1010_0110
  end
else if(NUMWAYS == 128)
  begin
    assign q[8] = d[8] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2]; //0x17C b-0001_0111_1100
  end
endmodule