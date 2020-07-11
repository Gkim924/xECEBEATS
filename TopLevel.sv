module toplevel(
    input logic            CLOCK, // Main Clock - 50Mhz
    input logic [3:0]      KEY,   // Left Most Key for Reset
    output logic [17:0]    LEDR,  // 18 Red Leds - can use for Debugging
    // HEX Display
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
    // Remote Interface
    input logic IRDA_RXD,

    // VGA Interface
    output logic [7:0]  VGA_R,        //VGA Red
                        VGA_G,        //VGA Green
                        VGA_B,        //VGA Blue
    output logic        VGA_CLK,      //VGA Clock
                        VGA_SYNC_N,   //VGA Sync signal
                        VGA_BLANK_N,  //VGA Blank signal
                        VGA_VS,       //VGA virtical sync signal
                        VGA_HS,       //VGA horizontal sync signal  

    // Flash Memory Interface 8MB
    output logic [22:0] FL_ADDR, // Flash memory Address - bit0 is signa to grab lower/upper byte
    input  wire  [7:0]  FL_DQ,   // Data read from memory address
    output logic        FL_OE_N, FL_RST_N, FL_WE_N, FL_CE_N, 

    // Audio Interface
    input logic         AUD_ADCDAT, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,
    output logic        AUD_DACDAT, AUD_XCK, I2C_SCLK, I2C_SDAT
);

logic Reset, start, PAUSE, RW, oDATA_READY;
// Remote Signals
logic ResetRemote, PlayPauseRemote, RestartRemote, KeycodeUpdateFlag, NextSongRemote, PrevSongRemote;
logic [31:0] Keycode;

// Playing Speeds
logic Fast=0, Slow=0;
// Graphics
logic [9:0] XCoord, YCoord;
logic [23:0] TitleColor, PlayPauseColor, SpeedColor;
logic [16:0] CoverPixel;
logic [13:0] TitlePixel;
logic [12:0] PlayPausePixel;
logic [11:0] SpeedPixel;
logic [3:0] CoverArtColor;
// Signal Sent to the colorMapper to display appropriate Covert Art
logic SecondSong;
logic [15:0] musicData;


always_ff @ (posedge CLOCK) begin
    LEDR[0] = oDATA_READY; // lights up breifly when a signal is received from Remote
    LEDR[1] = RW;// Playing
    LEDR[2] = ResetRemote;
    LEDR[3] = PlayPauseRemote;
    LEDR[4] = RestartRemote;
    LEDR[5] = PAUSE; // Pause State
    LEDR[6] = Fast; // Fast Playing Speed ~ Takes 85 secs to play a 42 sec clip
    LEDR[7] = Slow; // Slow Playing Speed ~ Takes 27 secs to play a 42 sec clip

    if (oDATA_READY) begin
        KeycodeUpdateFlag <=1; // Used a KeycodeUpdateFlag to give enough time for the keycode to update
    end                       // otherwise oldKeycode will be registred twice
    // Remote Keycode Table
    if(KeycodeUpdateFlag) begin
     case(Keycode[23:16])
        8'h12: ResetRemote <=1; // Reset - Power Button on Remote
        8'h16: PlayPauseRemote <=1; // Play/Pause Button on Remote
        8'h17: RestartRemote <=1; // Return Button on Remote
        8'h10: begin              // C Button on Remote
               Fast <=1; 
               Slow <=0;
               end
        8'h0f: begin              // A Button on Remote
               Slow <=1;
               Fast <=0;
               end
        8'h13: begin              // B Button On Remote
               Slow <=0;
               Fast <=0;
               end
        8'h18: NextSongRemote<=1;
        8'h14: PrevSongRemote<=1;
    endcase
    KeycodeUpdateFlag <=0;
    end
    else begin // Reset Signals
        ResetRemote <= 0; 
        PlayPauseRemote<= 0;
        RestartRemote <= 0;
        NextSongRemote<=0;
        PrevSongRemote<=0;
    end

    // Graphics
    CoverPixel <= ((YCoord-30) *300) +(XCoord-170);
    TitlePixel <=  ((YCoord-330) *300) +(XCoord-170);
    PlayPausePixel <= ((YCoord-390) *72) +(XCoord-284);
    SpeedPixel <= ((YCoord-401) *50) +(XCoord-220);

end

IR_RECEIVE IR(.*,      .iCLK(CLOCK),               //clk 50MHz
					.iRST_n(KEY[0]),            //reset					
					.iIRDA(IRDA_RXD),           //IR code input
					.oDATA(Keycode)             //output data,32bit 
            );

// Use PLL to generate the 25MHZ VGA_CLK.
vga_clk vga_clk_instance(.inclk0(CLOCK), .c0(VGA_CLK)); // Used for SLow music as well

VGA_controller vga_controller_instance(.*, .DrawX(XCoord), .DrawY(YCoord));

color_mapper color_instance(.*, .DrawX(XCoord), .DrawY(YCoord));

RAM Graphics(.*);


ControlUnit MusicControlUnit(.*);

HexDriver hex0(.In0(musicData[3:0]), .Out0(HEX0));
HexDriver hex1(.In0(musicData[7:4]), .Out0(HEX1));
HexDriver hex2(.In0(musicData[11:8]), .Out0(HEX2));
HexDriver hex3(.In0(musicData[15:12]), .Out0(HEX3));
// The two (important) hex values received from the remote receiver
HexDriver hex4(.In0(Keycode[19:16]), .Out0(HEX6));
HexDriver hex5(.In0(Keycode[23:20]), .Out0(HEX7));

sync button_sync[1:0] (CLOCK, {~KEY[0], ~KEY[1]}, {Reset, start});

endmodule