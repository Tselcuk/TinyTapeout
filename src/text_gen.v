/* Text Overlay Generator
 *
 * Draws static foreground text over the animated background. Rendering uses a
 * tiny hard-coded bitmap font so we avoid ROMs that would bloat the design.
 */
module text_gen (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    input  wire       next_frame,
    output reg        draw,
    output reg  [5:0] rgb
);

    localparam integer SCALE        = 2;
    localparam integer GLYPH_WIDTH  = 8;
    localparam integer GLYPH_HEIGHT = 8;
    localparam integer CHAR_WIDTH   = GLYPH_WIDTH * SCALE;  // 16 pixels wide glyphs
    localparam integer CHAR_HEIGHT  = GLYPH_HEIGHT * SCALE; // 16 pixels tall glyphs
    localparam integer LINE_GAP     = 4;
    localparam [9:0] CHAR_WIDTH_PX  = CHAR_WIDTH[9:0];
    localparam [9:0] CHAR_HEIGHT_PX = CHAR_HEIGHT[9:0];
    localparam [9:0] LINE_GAP_PX    = LINE_GAP[9:0];

    localparam [6:0] LINE0_LEN = 7'd8;
    localparam [6:0] LINE1_LEN = 7'd11;

    localparam [9:0] TEXT_LINE0_POS_X = 10'd256; // Center "WATERLOO"
    localparam [9:0] TEXT_LINE1_POS_X = 10'd232; // Center "ENGINEERING"
    localparam [10:0] TEXT_LINE0_RIGHT_FULL = TEXT_LINE0_POS_X + (LINE0_LEN * CHAR_WIDTH_PX);
    localparam [10:0] TEXT_LINE1_RIGHT_FULL = TEXT_LINE1_POS_X + (LINE1_LEN * CHAR_WIDTH_PX);
    localparam [9:0]  TEXT_LINE0_RIGHT     = TEXT_LINE0_RIGHT_FULL[9:0];
    localparam [9:0]  TEXT_LINE1_RIGHT     = TEXT_LINE1_RIGHT_FULL[9:0];

    localparam [9:0] TARGET_LINE0_Y0 = 10'd336;
    localparam [9:0] FALL_START_Y0   = 10'd0;
    localparam [9:0] FALL_STEP       = 10'd4;

    localparam [5:0] COLOR_TEXT = 6'b111111;

    // Character indices
    localparam [4:0] CH_SPACE = 5'd0;
    localparam [4:0] CH_W     = 5'd1;
    localparam [4:0] CH_A     = 5'd2;
    localparam [4:0] CH_T     = 5'd3;
    localparam [4:0] CH_E     = 5'd4;
    localparam [4:0] CH_R     = 5'd5;
    localparam [4:0] CH_L     = 5'd6;
    localparam [4:0] CH_O     = 5'd7;
    localparam [4:0] CH_N     = 5'd8;
    localparam [4:0] CH_G     = 5'd9;
    localparam [4:0] CH_I     = 5'd10;

    reg  [9:0] line0_base_y;

    wire [9:0] line0_y0 = line0_base_y;
    wire [10:0] line0_y1_full = line0_base_y + CHAR_HEIGHT_PX;
    wire [9:0]  line0_y1      = line0_y1_full[9:0];
    wire [10:0] line1_y0_full = line0_y1_full + LINE_GAP_PX;
    wire [9:0]  line1_y0      = line1_y0_full[9:0];
    wire [10:0] line1_y1_full = line1_y0_full + CHAR_HEIGHT_PX;
    wire [9:0]  line1_y1      = line1_y1_full[9:0];

    wire [9:0] line0_x_offset = x - TEXT_LINE0_POS_X;
    wire [9:0] line1_x_offset = x - TEXT_LINE1_POS_X;
    wire [9:0] line0_y_offset = y - line0_y0;
    wire [9:0] line1_y_offset = y - line1_y0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            line0_base_y <= FALL_START_Y0;
        end else if (next_frame && (line0_base_y < TARGET_LINE0_Y0)) begin
            if (line0_base_y + FALL_STEP >= TARGET_LINE0_Y0) begin
                line0_base_y <= TARGET_LINE0_Y0;
            end else begin
                line0_base_y <= line0_base_y + FALL_STEP;
            end
        end
    end

    reg [5:0] color_sel;
    reg       pixel_on;
    reg [6:0] char_index;
    reg [2:0] col_index;
    reg [2:0] row_index;
    reg [4:0] char_code;

    always @(*) begin
        draw       = 1'b0;
        color_sel  = 6'b000000;
        pixel_on   = 1'b0;
        char_index = 7'd0;
        col_index  = 3'd0;
        row_index  = 3'd0;
        char_code  = CH_SPACE;

        if (active) begin
            // Render "WATERLOO"
            if ((y >= line0_y0) && (y < line0_y1) &&
                (x >= TEXT_LINE0_POS_X) && (x < TEXT_LINE0_RIGHT)) begin
                char_index = {1'b0, line0_x_offset[9:4]};
                if (char_index < LINE0_LEN) begin
                    col_index = line0_x_offset[3:1];
                    row_index = line0_y_offset[3:1];
                    char_code = line0_code(char_index[4:0]);
                    pixel_on  = glyph_bit(char_code, row_index, col_index);
                end
            end
            // Render "ENGINEERING" beneath the top line
            else if ((y >= line1_y0) &&
                     (y < line1_y1) &&
                     (x >= TEXT_LINE1_POS_X) &&
                     (x < TEXT_LINE1_RIGHT)) begin
                char_index = {1'b0, line1_x_offset[9:4]};
                if (char_index < LINE1_LEN) begin
                    col_index = line1_x_offset[3:1];
                    row_index = line1_y_offset[3:1];
                    char_code = line1_code(char_index[4:0]);
                    pixel_on  = glyph_bit(char_code, row_index, col_index);
                end
            end
        end

        if (pixel_on) begin
            draw      = 1'b1;
            color_sel = COLOR_TEXT;
        end
    end

    always @(*) begin
        rgb = {
            color_sel[5],
            color_sel[3],
            color_sel[1],
            color_sel[4],
            color_sel[2],
            color_sel[0]
        };
    end

    function automatic [4:0] line0_code;
        input [4:0] index;
        begin
            case (index)
                5'd0: line0_code = CH_W;
                5'd1: line0_code = CH_A;
                5'd2: line0_code = CH_T;
                5'd3: line0_code = CH_E;
                5'd4: line0_code = CH_R;
                5'd5: line0_code = CH_L;
                5'd6: line0_code = CH_O;
                5'd7: line0_code = CH_O;
                default: line0_code = CH_SPACE;
            endcase
        end
    endfunction

    function automatic [4:0] line1_code;
        input [4:0] index;
        begin
            case (index)
                5'd0:  line1_code = CH_E;
                5'd1:  line1_code = CH_N;
                5'd2:  line1_code = CH_G;
                5'd3:  line1_code = CH_I;
                5'd4:  line1_code = CH_N;
                5'd5:  line1_code = CH_E;
                5'd6:  line1_code = CH_E;
                5'd7:  line1_code = CH_R;
                5'd8:  line1_code = CH_I;
                5'd9:  line1_code = CH_N;
                5'd10: line1_code = CH_G;
                default: line1_code = CH_SPACE;
            endcase
        end
    endfunction

    function automatic bit glyph_bit;
        input [4:0] code;
        input [2:0] row;
        input [2:0] col;
        reg [7:0] row_bits;
        begin
            row_bits = glyph_row(code, row);
            glyph_bit = row_bits[7 - col];
        end
    endfunction

    function automatic [7:0] glyph_row;
        input [4:0] code;
        input [2:0] row;
        begin
            case (code)
                CH_W: begin
                    case (row)
                        3'd0: glyph_row = 8'b10000001;
                        3'd1: glyph_row = 8'b10000001;
                        3'd2: glyph_row = 8'b10000001;
                        3'd3: glyph_row = 8'b10011001;
                        3'd4: glyph_row = 8'b10100101;
                        3'd5: glyph_row = 8'b11000011;
                        3'd6: glyph_row = 8'b11000011;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_A: begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111110;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_T: begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b00011000;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b00011000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_E: begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_R: begin
                    case (row)
                        3'd0: glyph_row = 8'b01111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01001000;
                        3'd5: glyph_row = 8'b01000100;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_L: begin
                    case (row)
                        3'd0: glyph_row = 8'b01000000;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01000000;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_O: begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_N: begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01100010;
                        3'd2: glyph_row = 8'b01010010;
                        3'd3: glyph_row = 8'b01001010;
                        3'd4: glyph_row = 8'b01000110;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_G: begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01001110;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                CH_I: begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b00011000;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                default: glyph_row = 8'b00000000;
            endcase
        end
    endfunction

    wire _unused_inputs = |{clk, rst, next_frame};

endmodule
