module waterloo_text_gen(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    output wire [5:0] rgb
);
    localparam [5:0] COLOR_TRANSPARENT = 6'b100001;
    localparam [5:0] COLOR_GOLD = 6'b110110;

    localparam [9:0] TEXT_Y0 = 325;
    localparam [9:0] CHAR_WIDTH = 10;  // Character width in pixels (scaled by 2)
    localparam [9:0] TOTAL_TEXT_WIDTH = 142;  // 12 chars * 10px + 11 spaces * 2px
    localparam [9:0] TEXT_X0 = 249;  // Left edge of text

    // Direct position-to-bitmap lookup
    // This compresses the transistors required by taking advantage of default values
    // For example: T originally had repeated 5'b00100, instead of writing this multiple times, we take advantage of the fact that we can use the default value of 5'b00100
    function automatic [4:0] get_char_bmp;
        input [3:0] pos;
        input [2:0] row;
        begin
            case (pos)
                4'd0: case (row) // W
                    3'd3: get_char_bmp = 5'b10101;
                    3'd4: get_char_bmp = 5'b10101;
                    3'd5: get_char_bmp = 5'b11011;
                    default: get_char_bmp = 5'b10001;
                endcase
                4'd1: case (row) // A
                    3'd0: get_char_bmp = 5'b01110;
                    3'd3: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b10001;
                endcase
                4'd2: case (row) // T
                    3'd0: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b00100;
                endcase
                4'd3, 4'd9: case (row) // E
                    3'd0: get_char_bmp = 5'b11111;
                    3'd3: get_char_bmp = 5'b11110;
                    3'd6: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b10000;
                endcase
                4'd4: case (row) // R
                    3'd0: get_char_bmp = 5'b11110;
                    3'd3: get_char_bmp = 5'b11110;
                    3'd4: get_char_bmp = 5'b10100;
                    3'd5: get_char_bmp = 5'b10010;
                    default: get_char_bmp = 5'b10001;
                endcase
                4'd5: case (row) // L
                    3'd6: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b10000;
                endcase
                4'd6, 4'd7: case (row) // O
                    3'd0: get_char_bmp = 5'b01110;
                    3'd6: get_char_bmp = 5'b01110;
                    default: get_char_bmp = 5'b10001;
                endcase
                4'd10: case (row) // N
                    3'd1: get_char_bmp = 5'b11001;
                    3'd2: get_char_bmp = 5'b10101;
                    3'd3: get_char_bmp = 5'b10101;
                    3'd4: get_char_bmp = 5'b10011;
                    default: get_char_bmp = 5'b10001;
                endcase
                4'd11: case (row) // G
                    3'd0: get_char_bmp = 5'b01110;
                    3'd2: get_char_bmp = 5'b10000;
                    3'd3: get_char_bmp = 5'b10111;
                    3'd6: get_char_bmp = 5'b01110;
                    default: get_char_bmp = 5'b10001;
                endcase
                default: get_char_bmp = 5'b00000; // Represents a space
            endcase
        end
    endfunction

    wire [9:0] rel_x = x - TEXT_X0;

    reg [3:0] char_pos;
    reg [9:0] char_x_offset;

    always @(*) begin
        if      (rel_x < 12*1)  begin char_pos = 0;  char_x_offset = rel_x - 12*0;  end
        else if (rel_x < 12*2)  begin char_pos = 1;  char_x_offset = rel_x - 12*1;  end
        else if (rel_x < 12*3)  begin char_pos = 2;  char_x_offset = rel_x - 12*2;  end
        else if (rel_x < 12*4)  begin char_pos = 3;  char_x_offset = rel_x - 12*3;  end
        else if (rel_x < 12*5)  begin char_pos = 4;  char_x_offset = rel_x - 12*4;  end
        else if (rel_x < 12*6)  begin char_pos = 5;  char_x_offset = rel_x - 12*5;  end
        else if (rel_x < 12*7)  begin char_pos = 6;  char_x_offset = rel_x - 12*6;  end
        else if (rel_x < 12*8)  begin char_pos = 7;  char_x_offset = rel_x - 12*7;  end
        else if (rel_x < 12*9)  begin char_pos = 8;  char_x_offset = rel_x - 12*8;  end
        else if (rel_x < 12*10) begin char_pos = 9;  char_x_offset = rel_x - 12*9;  end
        else if (rel_x < 12*11) begin char_pos = 10; char_x_offset = rel_x - 12*10; end
        else /*(rel_x < 12*12)*/begin char_pos = 11; char_x_offset = rel_x - 12*11; end
    end

    // Scale down coordinates by 2 to index into base 5x7 bitmap
    wire [2:0] pixel_x = char_x_offset[3:1];
    // Rational: We only need the bottom 4 bits of y - TEXT_Y0, so we can safely ignore the warning
    /* verilator lint_off WIDTH */
    wire [2:0] pixel_y = (y - TEXT_Y0) >> 1; // Gets bits 3:1 of y - TEXT_Y0
    /* verilator lint_on WIDTH */

    wire [4:0] char_row_data = get_char_bmp(char_pos, pixel_y);
    wire is_text_pixel = active && (y >= TEXT_Y0) && (y < TEXT_Y0 + 14) && (rel_x < TOTAL_TEXT_WIDTH) && (char_x_offset < CHAR_WIDTH) && char_row_data[4 - pixel_x];

    assign rgb = is_text_pixel ? COLOR_GOLD : COLOR_TRANSPARENT;

endmodule
