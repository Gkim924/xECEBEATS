// color_mapper: Decide which color to be output to VGA for each pixel.
module  color_mapper (input  [23:0] TitleColor,PlayPauseColor,SpeedColor,
                      input  [3:0] CoverArtColor,									  
                      input  [9:0] DrawX, DrawY,       // Current pixel coordinates
                      input        RW, Fast,SecondSong, // PLAYING Signal
                      output logic [7:0] VGA_R, VGA_G, VGA_B // VGA RGB output
);
    
    logic [7:0] Red, Green, Blue;
    
    // Output colors to VGA
    assign VGA_R = Red;
    assign VGA_G = Green;
    assign VGA_B = Blue;
    // Assign color based on is_ball signal
    always_comb
    begin
        
        if ((DrawX >= 170 && DrawX <= 470) && (DrawY >= 31 && DrawY <= 329)) 
        begin
            if(~SecondSong)begin
            case(CoverArtColor)
                4'b0000: begin 
                            Red = 8'hd7;
                            Green = 8'h1c;
                            Blue = 8'h1c;
                         end
                4'b0001: begin
                            Red = 8'hfd;
                            Green = 8'hd6;
                            Blue = 8'hd6;
                        end
                4'b0010: begin
                            Red = 8'h14;
                            Green = 8'h12;
                            Blue = 8'h12;
                        end
                4'b0011: begin
                            Red = 8'h3d;
                            Green = 8'h3b;
                            Blue = 8'h3b;
                        end
                default:begin
                        Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
                        Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
                        Blue = 8'h9b;
                        end
            endcase
            end
            else begin
                case(CoverArtColor)
                4'b0000: begin 
                            Red = 8'hd8;
                            Green = 8'haa;
                            Blue = 8'hcc;
                         end
                4'b0001: begin
                            Red = 8'ha8;
                            Green = 8'h6b;
                            Blue = 8'h96;
                        end       
                default:begin
                        Red = 8'h00; 
                        Green = 8'h00;
                        Blue = 8'h00;
                        end
            endcase
            end
        end

        else if ((DrawX >= 170 && DrawX <= 470) && (DrawY >= 330 && DrawY <= 380)) 
        begin
            if (TitleColor[23:20] == 4'hf) begin
                Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
                Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
                Blue = 8'h9b;
            end
            else begin
            Red = TitleColor[23:16];
            Green = TitleColor[15:8];
            Blue = TitleColor[7:0];
            end
        end
        else if ((DrawX >= 284 && DrawX <= 356) && (DrawY >= 390 && DrawY <= 462)) 
        begin
            if (RW)
            begin
                Red = PlayPauseColor[23:16];
                Green = PlayPauseColor[15:8];
                Blue = PlayPauseColor[7:0];

                if (PlayPauseColor == 0) 
                begin
                    Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
                    Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
                    Blue = 8'h9b;
                end
            end
            else 
            begin
                Red = 8'hab;
                Green = 8'h34;
                Blue = 8'h34;
                if (PlayPauseColor == 0) 
                begin
                    Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
                    Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
                    Blue = 8'h9b;
                end
            end
        end           
        else if ((DrawX >= 221 && DrawX <= 270) && (DrawY >= 401 && DrawY <= 450) && RW &&Fast) 
        begin
            Red = SpeedColor[23:16];
            Green = SpeedColor[15:8];
            Blue = SpeedColor[7:0];

            if (SpeedColor == 24'hffffff) begin
                Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
                Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
                Blue = 8'h9b;
            end
        end  
        else 
        begin
            // Background with nice color gradient
            Red = 8'hff- {1'b0, DrawX[9:3]}-60; 
            Green = 8'hd8- {1'b0, DrawX[9:3]}-60;
            Blue = 8'h9b;
        end
    end 
    
endmodule
