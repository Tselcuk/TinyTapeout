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
                0: case (row) // W
                    3, 4: get_char_bmp = 5'b10101;
                    5: get_char_bmp = 5'b11011;
                    default: get_char_bmp = 5'b10001;
                endcase
                1: case (row) // A
                    0: get_char_bmp = 5'b01110;
                    3: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b10001;
                endcase
                2: case (row) // T
                    0: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b00100;
                endcase
                3, 9: case (row) // E
                    0, 6: get_char_bmp = 5'b11111;
                    3: get_char_bmp = 5'b11110;
                    default: get_char_bmp = 5'b10000;
                endcase
                4: case (row) // R
                    0, 3: get_char_bmp = 5'b11110;
                    4: get_char_bmp = 5'b10100;
                    5: get_char_bmp = 5'b10010;
                    default: get_char_bmp = 5'b10001;
                endcase
                5: case (row) // L
                    6: get_char_bmp = 5'b11111;
                    default: get_char_bmp = 5'b10000;
                endcase
                6, 7: case (row) // O
                    0, 6: get_char_bmp = 5'b01110;
                    default: get_char_bmp = 5'b10001;
                endcase
                10: case (row) // N
                    1: get_char_bmp = 5'b11001;
                    2, 3: get_char_bmp = 5'b10101;
                    4: get_char_bmp = 5'b10011;
                    default: get_char_bmp = 5'b10001;
                endcase
                11: case (row) // G
                    0, 6: get_char_bmp = 5'b01110;
                    2: get_char_bmp = 5'b10000;
                    3: get_char_bmp = 5'b10111;
                    default: get_char_bmp = 5'b10001;
                endcase
                default: get_char_bmp = 5'b00000; // Represents a space
            endcase
        end
    endfunction

    wire [9:0] rel_x = x - TEXT_X0;

    reg [3:0] char_pos;
    reg [9:0] char_x_offset;

    wire [9:0] char_pos_x12 = {3'b0, char_pos, 3'b0} + {4'b0, char_pos, 2'b0};  // 12 * char_pos

    always @(*) begin
        if      (rel_x < 12)  char_pos = 0;
        else if (rel_x < 24)  char_pos = 1;
        else if (rel_x < 36)  char_pos = 2;
        else if (rel_x < 48)  char_pos = 3;
        else if (rel_x < 60)  char_pos = 4;
        else if (rel_x < 72)  char_pos = 5;
        else if (rel_x < 84)  char_pos = 6;
        else if (rel_x < 96)  char_pos = 7;
        else if (rel_x < 108) char_pos = 8;
        else if (rel_x < 120) char_pos = 9;
        else if (rel_x < 132) char_pos = 10;
        else                  char_pos = 11;
        
        // Compute offset once using the pre-computed multiplication
        char_x_offset = rel_x - char_pos_x12;
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
