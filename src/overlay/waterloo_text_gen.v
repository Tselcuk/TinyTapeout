module waterloo_text_gen(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    output reg draw,
    output reg [5:0] rgb
);

    localparam [5:0] COLOR_GOLD = 6'b110110;

    // Text positioning - centered below the emblem
    localparam [9:0] TEXT_Y0 = 325;
    localparam [9:0] TEXT_HEIGHT = 14; // 7 rows * 2 (doubled)
    localparam [9:0] CHAR_WIDTH = 10;  // 5 pixels * 2 (doubled)
    localparam [9:0] CHAR_SPACING = 2; // 1 pixel * 2 (doubled)

    // Center position (emblem center is at x=320)
    localparam [9:0] TEXT_CENTER_X = 320;

    // "WATERLOO ENG" = 12 characters
    localparam [9:0] TOTAL_TEXT_WIDTH = 12 * CHAR_WIDTH + 11 * CHAR_SPACING;
    localparam [9:0] TEXT_X0 = TEXT_CENTER_X - (TOTAL_TEXT_WIDTH >> 1);

    // Direct position-to-bitmap lookup for "WATERLOO ENG"
    // Optimized to save transistors by eliminating intermediate 8-bit char representation
    function automatic [4:0] get_char_bitmap_direct;
        input [3:0] pos;
        input [2:0] row;
        begin
            case (pos)
                // Position 0: W
                4'd0: case (row)
                    3'd0: get_char_bitmap_direct = 5'b10001;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10001;
                    3'd3: get_char_bitmap_direct = 5'b10101;
                    3'd4: get_char_bitmap_direct = 5'b10101;
                    3'd5: get_char_bitmap_direct = 5'b11011;
                    3'd6: get_char_bitmap_direct = 5'b10001;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 1: A
                4'd1: case (row)
                    3'd0: get_char_bitmap_direct = 5'b01110;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10001;
                    3'd3: get_char_bitmap_direct = 5'b11111;
                    3'd4: get_char_bitmap_direct = 5'b10001;
                    3'd5: get_char_bitmap_direct = 5'b10001;
                    3'd6: get_char_bitmap_direct = 5'b10001;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 2: T
                4'd2: case (row)
                    3'd0: get_char_bitmap_direct = 5'b11111;
                    3'd1: get_char_bitmap_direct = 5'b00100;
                    3'd2: get_char_bitmap_direct = 5'b00100;
                    3'd3: get_char_bitmap_direct = 5'b00100;
                    3'd4: get_char_bitmap_direct = 5'b00100;
                    3'd5: get_char_bitmap_direct = 5'b00100;
                    3'd6: get_char_bitmap_direct = 5'b00100;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 3: E
                4'd3: case (row)
                    3'd0: get_char_bitmap_direct = 5'b11111;
                    3'd1: get_char_bitmap_direct = 5'b10000;
                    3'd2: get_char_bitmap_direct = 5'b10000;
                    3'd3: get_char_bitmap_direct = 5'b11110;
                    3'd4: get_char_bitmap_direct = 5'b10000;
                    3'd5: get_char_bitmap_direct = 5'b10000;
                    3'd6: get_char_bitmap_direct = 5'b11111;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 4: R
                4'd4: case (row)
                    3'd0: get_char_bitmap_direct = 5'b11110;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10001;
                    3'd3: get_char_bitmap_direct = 5'b11110;
                    3'd4: get_char_bitmap_direct = 5'b10100;
                    3'd5: get_char_bitmap_direct = 5'b10010;
                    3'd6: get_char_bitmap_direct = 5'b10001;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 5: L
                4'd5: case (row)
                    3'd0: get_char_bitmap_direct = 5'b10000;
                    3'd1: get_char_bitmap_direct = 5'b10000;
                    3'd2: get_char_bitmap_direct = 5'b10000;
                    3'd3: get_char_bitmap_direct = 5'b10000;
                    3'd4: get_char_bitmap_direct = 5'b10000;
                    3'd5: get_char_bitmap_direct = 5'b10000;
                    3'd6: get_char_bitmap_direct = 5'b11111;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 6: O
                4'd6: case (row)
                    3'd0: get_char_bitmap_direct = 5'b01110;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10001;
                    3'd3: get_char_bitmap_direct = 5'b10001;
                    3'd4: get_char_bitmap_direct = 5'b10001;
                    3'd5: get_char_bitmap_direct = 5'b10001;
                    3'd6: get_char_bitmap_direct = 5'b01110;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 7: O
                4'd7: case (row)
                    3'd0: get_char_bitmap_direct = 5'b01110;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10001;
                    3'd3: get_char_bitmap_direct = 5'b10001;
                    3'd4: get_char_bitmap_direct = 5'b10001;
                    3'd5: get_char_bitmap_direct = 5'b10001;
                    3'd6: get_char_bitmap_direct = 5'b01110;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 8: Space
                4'd8: get_char_bitmap_direct = 5'b00000;
                // Position 9: E
                4'd9: case (row)
                    3'd0: get_char_bitmap_direct = 5'b11111;
                    3'd1: get_char_bitmap_direct = 5'b10000;
                    3'd2: get_char_bitmap_direct = 5'b10000;
                    3'd3: get_char_bitmap_direct = 5'b11110;
                    3'd4: get_char_bitmap_direct = 5'b10000;
                    3'd5: get_char_bitmap_direct = 5'b10000;
                    3'd6: get_char_bitmap_direct = 5'b11111;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 10: N
                4'd10: case (row)
                    3'd0: get_char_bitmap_direct = 5'b10001;
                    3'd1: get_char_bitmap_direct = 5'b11001;
                    3'd2: get_char_bitmap_direct = 5'b10101;
                    3'd3: get_char_bitmap_direct = 5'b10101;
                    3'd4: get_char_bitmap_direct = 5'b10011;
                    3'd5: get_char_bitmap_direct = 5'b10001;
                    3'd6: get_char_bitmap_direct = 5'b10001;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                // Position 11: G
                4'd11: case (row)
                    3'd0: get_char_bitmap_direct = 5'b01110;
                    3'd1: get_char_bitmap_direct = 5'b10001;
                    3'd2: get_char_bitmap_direct = 5'b10000;
                    3'd3: get_char_bitmap_direct = 5'b10111;
                    3'd4: get_char_bitmap_direct = 5'b10001;
                    3'd5: get_char_bitmap_direct = 5'b10001;
                    3'd6: get_char_bitmap_direct = 5'b01110;
                    default: get_char_bitmap_direct = 5'b00000;
                endcase
                default: get_char_bitmap_direct = 5'b00000;
            endcase
        end
    endfunction

    wire [9:0] rel_x = x - TEXT_X0;

    // Calculate character position using comparison chain (cheaper than division)
    // CHAR_WIDTH (10) + CHAR_SPACING (2) = 12 pixels per character
    wire [3:0] char_pos =
        (rel_x < 10'd12)  ? 4'd0 :
        (rel_x < 10'd24)  ? 4'd1 :
        (rel_x < 10'd36)  ? 4'd2 :
        (rel_x < 10'd48)  ? 4'd3 :
        (rel_x < 10'd60)  ? 4'd4 :
        (rel_x < 10'd72)  ? 4'd5 :
        (rel_x < 10'd84)  ? 4'd6 :
        (rel_x < 10'd96)  ? 4'd7 :
        (rel_x < 10'd108) ? 4'd8 :
        (rel_x < 10'd120) ? 4'd9 :
        (rel_x < 10'd132) ? 4'd10 :
        (rel_x < 10'd144) ? 4'd11 : 4'd0;

    // Calculate offset within character (0-11) without multiplication
    wire [9:0] char_x_offset =
        (char_pos == 4'd0)  ? rel_x :
        (char_pos == 4'd1)  ? rel_x - 10'd12 :
        (char_pos == 4'd2)  ? rel_x - 10'd24 :
        (char_pos == 4'd3)  ? rel_x - 10'd36 :
        (char_pos == 4'd4)  ? rel_x - 10'd48 :
        (char_pos == 4'd5)  ? rel_x - 10'd60 :
        (char_pos == 4'd6)  ? rel_x - 10'd72 :
        (char_pos == 4'd7)  ? rel_x - 10'd84 :
        (char_pos == 4'd8)  ? rel_x - 10'd96 :
        (char_pos == 4'd9)  ? rel_x - 10'd108 :
        (char_pos == 4'd10) ? rel_x - 10'd120 :
        rel_x - 10'd132; // char_pos == 11

    // Scale down coordinates by 2 to index into base 5x7 bitmap (saves transistors)
    wire [2:0] pixel_x = char_x_offset[3:1]; // Divide by 2 to get bitmap column (0-4)
    // verilator lint_off UNUSEDSIGNAL
    wire [9:0] temp_y_scaled_full = (y - TEXT_Y0) >> 1;
    // verilator lint_on UNUSEDSIGNAL
    wire [2:0] temp_y_scaled = temp_y_scaled_full[2:0];
    wire [2:0] pixel_y = temp_y_scaled;  // Divide by 2 to get bitmap row (0-6)

    // Direct lookup without intermediate char representation
    wire [4:0] char_row_data = get_char_bitmap_direct(char_pos, pixel_y);

    wire in_text_bounds = (active && (y >= TEXT_Y0) && (y < (TEXT_Y0 + TEXT_HEIGHT)) &&
                           (rel_x < TOTAL_TEXT_WIDTH) && (char_x_offset < CHAR_WIDTH));
    wire pixel_on = char_row_data[4 - pixel_x];

    always @(*) begin
        draw = 1'b0;
        rgb = COLOR_GOLD;

        if (in_text_bounds && pixel_on) begin
            draw = 1'b1;
        end
    end

endmodule
