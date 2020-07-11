module memreader ( input CLOCK, VGA_CLK, Reset,

                   // Signal recieved from the audio interface to start sequential read
                   data_over,RW,
                    
                   // Remote Interface
                   ResetRemote, PlayPauseRemote, RestartRemote, Fast, Slow, NextSongRemote, PrevSongRemote,
                                       
                   // MEMORY INTERFACE
                   output logic [22:0] FL_ADDR,// Mem address
                   input        [7:0]  FL_DQ,// Data received from Memory
                   output logic        FL_OE_N, FL_RST_N, FL_WE_N, FL_CE_N,

                   // FULL 16-bit DATA COLLECTED,
                   output logic [15:0] musicData,
                   // Signal Sent to the colorMapper to display appropriate Covert Art
                   output logic SecondSong
);

// States for the state Machine
enum logic [4:0] {idle, LowerByte, UpperByte, increment} state, next_state;

logic ADDSignal, clk; // Clock Signal is used to control the speed of the music
always_ff @( posedge  clk) begin
if (Reset || ResetRemote || (RestartRemote && ~SecondSong)|| PrevSongRemote || FL_ADDR[22:1] == 2274216) begin // *If Return pressed then start reading from the starting address
    state<= idle;
    SecondSong<=0;
    FL_ADDR[22:1] <=0;
end
if (NextSongRemote || (RestartRemote && SecondSong) || FL_ADDR[22:1] == -1) begin
    SecondSong<=1;
    FL_ADDR[22:1] <= 2274217;
end
	state <= next_state;
if (FL_ADDR[0] ==0) begin
        musicData[7:0] <= FL_DQ;// GET LOWER BYTE
end
else begin
        musicData[15:8] <= FL_DQ;// GET UPPER BYTE
end
if(ADDSignal) begin
    FL_ADDR[22:1] <= FL_ADDR[22:1] +1; // INCREMENT ADDRESS
end
end

always_comb begin
    next_state = state;
    FL_RST_N= 1;
    FL_WE_N = 1;
    FL_CE_N = 0;
    FL_OE_N = 0;
	FL_ADDR[0] =0;
    ADDSignal = 0;
    unique case(state)
    idle: 
            next_state = LowerByte;
    LowerByte: 
            next_state= UpperByte;
    UpperByte:
            if (RW && data_over)
             next_state= increment;
            else
            next_state = LowerByte;

    increment: 
            if (Fast) 
                next_state= LowerByte;
            else
                next_state= idle;
    endcase

    case(state)
        UpperByte: // Switch from reading Lower byte to Upper
            FL_ADDR[0] =1;
            increment: ADDSignal=1;
    endcase

    if(Slow) // if Button A pressed then use VGA Clock for Reading ~ Slow Clock 25MHz
        clk = VGA_CLK;
    else
        clk = CLOCK;
end

endmodule