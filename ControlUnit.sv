module ControlUnit(input CLOCK,VGA_CLK, 
                    // Board Keys Signals
                    Reset, start, // Key[0] for Reset, Key[1] for Start

                    // Remote Interface
                    ResetRemote, PlayPauseRemote, RestartRemote, Fast, Slow, NextSongRemote,PrevSongRemote,

                    // Audio interface
                    input logic AUD_ADCDAT, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,
	                output logic AUD_DACDAT, AUD_XCK, I2C_SCLK, I2C_SDAT,

                    // State Signals
                    output logic RW, PAUSE, // used in Toplevel for Debugging
                    
                    // MEMORY INTERFACE
                    output logic [22:0] FL_ADDR,// Mem address
                    input        [7:0]  FL_DQ,// Data received from Memory
                    output logic        FL_OE_N, FL_RST_N, FL_WE_N, FL_CE_N,

                    // Music Data
                    output logic [15:0] musicData, // 16-bit DATA COLLECTED from memory - GOES TO LEFT/RIGHT
    
                   // Signal Sent to the colorMapper to display appropriate Covert Art
                   output logic SecondSong
);
// Initilization Signals
logic INIT_FINISH;
// States for the state Machine
enum logic [3:0] {idle, init, Pause, Play} state, next_state;

always_ff @(posedge CLOCK) begin
	if (Reset || ResetRemote ) begin
		state <= idle;
	end
    else
	state <= next_state;
end

always_comb begin
	next_state = state;
    RW =0;
    PAUSE =0;
    unique case(state)
        idle:
                next_state = init;
                
        init: if (INIT_FINISH)
                 next_state = Pause;

        Play:if (PlayPauseRemote || start) // If in Play state and button signal is received then Pause
                 next_state = Pause;

        Pause:if (PlayPauseRemote || start) // If in Pause state and button signal is received then Play
                 next_state = Play; 
    endcase

    case(state)
        idle: ;
        init:;
        Play: RW =1;
        Pause: PAUSE =1;
    endcase
end

logic data_over;

audio_interface audioInterface_instance(.clk(CLOCK),
                               .Reset(Reset),
                               .INIT(PlayPauseRemote),
                               .LDATA(musicData), // parallel external data inputs
                               .RDATA(musicData), // parallel external data inputs
                               .AUD_BCLK(AUD_BCLK), // Digital Audio bit clock
                               .AUD_ADCDAT(AUD_ADCDAT),
                               .AUD_DACLRCK(AUD_DACLRCK), .AUD_ADCLRCK(AUD_ADCLRCK), // DAC data left/right select
                               // OUTPUTS
                               .INIT_FINISH(INIT_FINISH),
                               .adc_full(),
                               .data_over(data_over), //sample sync pulse
                               .AUD_MCLK(AUD_XCK), // Codec master clock OUTPUT
                               .AUD_DACDAT(AUD_DACDAT), // DAC data line
                               .I2C_SDAT(I2C_SDAT), // serial interface data line
                               .I2C_SCLK(I2C_SCLK), // serial interface clock
                               .ADCDATA()// might need to use for visualization
);

memreader flash(.*);

endmodule