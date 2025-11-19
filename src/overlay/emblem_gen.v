module emblem_gen(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    output reg draw,
    output reg [5:0] rgb
);

    localparam [9:0] EMBLEM_X0 = 240;
    localparam [9:0] EMBLEM_X1 = 400;
    localparam [9:0] EMBLEM_Y0 = 144;
    localparam [9:0] EMBLEM_Y1 = 320;
    localparam [9:0] EMBLEM_CENTER_X = (EMBLEM_X0 + EMBLEM_X1) >> 1;

    localparam [5:0] COLOR_BLACK = 6'b000000;
    localparam [5:0] COLOR_GOLD = 6'b110110;
    localparam [5:0] COLOR_RED = 6'b100100;
    localparam [5:0] COLOR_WHITE = 6'b111111;

    localparam [9:0] BORDER_THICKNESS = 3;

    // Chevron parameters
    // Original bitmap: 85 pixels wide, 100 pixels tall
    // Scaled 2x for display: 170 pixels wide, 200 pixels tall
    localparam [9:0] CHEVRON_BITMAP_WIDTH = 85;
    localparam [9:0] CHEVRON_BITMAP_HEIGHT = 100;
    localparam [9:0] CHEVRON_SCALE = 2;  // 2x scale
    localparam [9:0] CHEVRON_WIDTH = CHEVRON_BITMAP_WIDTH * CHEVRON_SCALE;  // 170 pixels
    localparam [9:0] CHEVRON_HEIGHT = CHEVRON_BITMAP_HEIGHT * CHEVRON_SCALE;  // 200 pixels
    localparam [9:0] CHEVRON_X = EMBLEM_CENTER_X - (CHEVRON_WIDTH >> 1);
    localparam [9:0] CHEVRON_Y = EMBLEM_Y0;  // Positioned at top of emblem

    localparam integer LION_WIDTH_PIX = 48;
    localparam [9:0] LION_WIDTH = 48;
    localparam [9:0] LION_HEIGHT = 45;
    localparam [9:0] TOP_LION_Y = EMBLEM_Y0 + 16;
    localparam [9:0] BOTTOM_LION_Y = EMBLEM_Y0 + 112;
    localparam [9:0] LEFT_LION_X = EMBLEM_X0 + 20;
    localparam [9:0] RIGHT_LION_X = EMBLEM_X1 - 20 - LION_WIDTH;
    localparam [9:0] CENTER_LION_X = EMBLEM_CENTER_X - (LION_WIDTH >> 1);

    function automatic [LION_WIDTH_PIX-1:0] lion_row;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  lion_row = 48'h00001C000000;
                6'd1:  lion_row = 48'h00001FC00000;
                6'd2:  lion_row = 48'h2000FFE00000;
                6'd3:  lion_row = 48'h3202FFF00000;
                6'd4:  lion_row = 48'h3A01FFFC00E0;
                6'd5:  lion_row = 48'h3F81FFFCC1F8;
                6'd6:  lion_row = 48'h3FC7FFF8C1FC;
                6'd7:  lion_row = 48'h1FE1FF99C1F8;
                6'd8:  lion_row = 48'h1FF1FFFFC3FC;
                6'd9:  lion_row = 48'h0FF3FFC007FE;
                6'd10: lion_row = 48'h01F7FFF01FF0;
                6'd11: lion_row = 48'h30F1FFCCBFF8;
                6'd12: lion_row = 48'h3071FFFFFF90;
                6'd13: lion_row = 48'h3F33FFFFFF80;
                6'd14: lion_row = 48'h3F33FFFFFF80;
                6'd15: lion_row = 48'h1FE07FFFFF00;
                6'd16: lion_row = 48'h0FE07FFFFD00;
                6'd17: lion_row = 48'h03C0FFFFF800;
                6'd18: lion_row = 48'h31801FFFFC00;
                6'd19: lion_row = 48'h39803FFFFC00;
                6'd20: lion_row = 48'h3F003FFFFE00;
                6'd21: lion_row = 48'h1F002FFFEF80;
                6'd22: lion_row = 48'h0E003FC07FFC;
                6'd23: lion_row = 48'h0E00FFFFFFFE;
                6'd24: lion_row = 48'h0C01FFFFFFFC;
                6'd25: lion_row = 48'h0C07FFFFFFFF;
                6'd26: lion_row = 48'h080FFFFA4FFF;
                6'd27: lion_row = 48'h081FFE0088FC;
                6'd28: lion_row = 48'h0C3FFF8000F8;
                6'd29: lion_row = 48'h0C3FFFF80058;
                6'd30: lion_row = 48'h071FFFFE0000;
                6'd31: lion_row = 48'h03FFFFFE0000;
                6'd32: lion_row = 48'h003FFFFF0000;
                6'd33: lion_row = 48'h0007FEFF0000;
                6'd34: lion_row = 48'h0007FEFF0000;
                6'd35: lion_row = 48'h0007FEFF0000;
                6'd36: lion_row = 48'h007FFE7F0000;
                6'd37: lion_row = 48'h00FFFC7F8C00;
                6'd38: lion_row = 48'h01FFE07FDE00;
                6'd39: lion_row = 48'h01FF403FFE00;
                6'd40: lion_row = 48'h01FF001BFF00;
                6'd41: lion_row = 48'h01FF0009FF80;
                6'd42: lion_row = 48'h00FF00007E00;
                6'd43: lion_row = 48'h003F8C007E00;
                6'd44: lion_row = 48'h0017FC006200;
                default: lion_row = 48'h000000000000;
            endcase
        end
    endfunction

    wire is_lion_pixel;
    reg [9:0] lion_col_offset;
    reg [9:0] lion_row_offset;
    reg lion_box_hit;

    always @(*) begin
        lion_box_hit = 1'b0;
        // Default assignments to prevent latches
        lion_col_offset = 0;
        lion_row_offset = 0;

        // Check if the pixel is within the Y-range of the top two lions
        if (y >= TOP_LION_Y && y < (TOP_LION_Y + LION_HEIGHT)) begin
            // Check for top-left lion
            if (x >= LEFT_LION_X && x < (LEFT_LION_X + LION_WIDTH)) begin
                lion_col_offset = x - LEFT_LION_X;
                lion_row_offset = y - TOP_LION_Y;
                lion_box_hit = 1'b1;
            // Check for top-right lion
            end else if (x >= RIGHT_LION_X && x < (RIGHT_LION_X + LION_WIDTH)) begin
                lion_col_offset = x - RIGHT_LION_X;
                lion_row_offset = y - TOP_LION_Y;
                lion_box_hit = 1'b1;
            end
        // Check if the pixel is within the Y-range of the bottom lion
        end else if (y >= BOTTOM_LION_Y && y < (BOTTOM_LION_Y + LION_HEIGHT)) begin
            // Check for bottom lion
            if (x >= CENTER_LION_X && x < (CENTER_LION_X + LION_WIDTH)) begin
                lion_col_offset = x - CENTER_LION_X;
                lion_row_offset = y - BOTTOM_LION_Y;
                lion_box_hit = 1'b1;
            end
        end
    end

    // Look up the pixel from the bitmap ROM only if it was inside one of the lion boxes
    wire [LION_WIDTH_PIX-1:0] lion_mask = lion_row(lion_row_offset[5:0]);
    assign is_lion_pixel = lion_box_hit ? lion_mask[lion_col_offset[5:0]] : 1'b0;

    function automatic [95:0] chevron_row;
        input [6:0] idx;
        begin
            case (idx)
                7'd0:  chevron_row = 96'h000000000000000000000000;
                7'd1:  chevron_row = 96'h000000000000000000000000;
                7'd2:  chevron_row = 96'h000000000000000000000000;
                7'd3:  chevron_row = 96'h000000000000000000000000;
                7'd4:  chevron_row = 96'h000000000000000000000000;
                7'd5:  chevron_row = 96'h000000000000000000000000;
                7'd6:  chevron_row = 96'h000000000000000000000000;
                7'd7:  chevron_row = 96'h000000000000000000000000;
                7'd8:  chevron_row = 96'h000000000000000000000000;
                7'd9:  chevron_row = 96'h000000000000000000000000;
                7'd10: chevron_row = 96'h000000000000000000000000;
                7'd11: chevron_row = 96'h000000000000000000000000;
                7'd12: chevron_row = 96'h000000000000000000000000;
                7'd13: chevron_row = 96'h000000000000000000000000;
                7'd14: chevron_row = 96'h000000000000000000000000;
                7'd15: chevron_row = 96'h000000000000000000000000;
                7'd16: chevron_row = 96'h000000000000000000000000;
                7'd17: chevron_row = 96'h000000000000000000000000;
                7'd18: chevron_row = 96'h000000000000000000000000;
                7'd19: chevron_row = 96'h000000000000000000000000;
                7'd20: chevron_row = 96'h000000000000000000000000;
                7'd21: chevron_row = 96'h000000000000000000000000;
                7'd22: chevron_row = 96'h000000000000000000000000;
                7'd23: chevron_row = 96'h000000000000000000000000;
                7'd24: chevron_row = 96'h000000000000000000000000;
                7'd25: chevron_row = 96'h000000000000000000000000;
                7'd26: chevron_row = 96'h000000000000000000000000;
                7'd27: chevron_row = 96'h000000000000000000000000;
                7'd28: chevron_row = 96'h000000000000000000000000;
                7'd29: chevron_row = 96'h000000000000000000000000;
                7'd30: chevron_row = 96'h000000000040000000000000;
                7'd31: chevron_row = 96'h000000000088000000000000;
                7'd32: chevron_row = 96'h000000000104000000000000;
                7'd33: chevron_row = 96'h000000000000000000000000;
                7'd34: chevron_row = 96'h000000000800000000000000;
                7'd35: chevron_row = 96'h000000001000000000000000;
                7'd36: chevron_row = 96'h000000002000000000000000;
                7'd37: chevron_row = 96'h000000000070100000000000;
                7'd38: chevron_row = 96'h0000000000F8000000000000;
                7'd39: chevron_row = 96'h0000000203FC020000000000;
                7'd40: chevron_row = 96'h0000000407FF010000000000;
                7'd41: chevron_row = 96'h000000000FFF800000000000;
                7'd42: chevron_row = 96'h000000201FFFC00000000000;
                7'd43: chevron_row = 96'h000000407FFFE01000000000;
                7'd44: chevron_row = 96'h00000080FFFFF00800000000;
                7'd45: chevron_row = 96'h00000001FFDFFC0400000000;
                7'd46: chevron_row = 96'h00000003FF0FFE0000000000;
                7'd47: chevron_row = 96'h0000000FFE03FF0000000000;
                7'd48: chevron_row = 96'h0000101FFC01FFC040000000;
                7'd49: chevron_row = 96'h0000403FF000FFE000000000;
                7'd50: chevron_row = 96'h0000807FE0007FF000000000;
                7'd51: chevron_row = 96'h000101FFC0001FF804000000;
                7'd52: chevron_row = 96'h000203FF80800FFE02000000;
                7'd53: chevron_row = 96'h000007FF010407FF01000000;
                7'd54: chevron_row = 96'h00000FFC000003FF80000000;
                7'd55: chevron_row = 96'h00003FF8080100FFC0000000;
                7'd56: chevron_row = 96'h00007FF01000007FF0100000;
                7'd57: chevron_row = 96'h0000FFC02000203FF8000000;
                7'd58: chevron_row = 96'h0001FF804000100FFC020000;
                7'd59: chevron_row = 96'h0007FF0000000807FE060000;
                7'd60: chevron_row = 96'h000FFE0200000003FF800000;
                7'd61: chevron_row = 96'h001FFC0400000101FFC80000;
                7'd62: chevron_row = 96'h003FF00000000080FFC00000;
                7'd63: chevron_row = 96'h001FE020000000003FD00000;
                7'd64: chevron_row = 96'h001FC040000000101F900000;
                7'd65: chevron_row = 96'h004F0080000000080F800000;
                7'd66: chevron_row = 96'h000E01000000000403200000;
                7'd67: chevron_row = 96'h002406000000000201000000;
                7'd68: chevron_row = 96'h000008000000000000400000;
                7'd69: chevron_row = 96'h000010000000000040000000;
                7'd70: chevron_row = 96'h000000000000000020800000;
                7'd71: chevron_row = 96'h000000000000000010000000;
                7'd72: chevron_row = 96'h000080000000000005000000;
                7'd73: chevron_row = 96'h000000000000000002000000;
                7'd74: chevron_row = 96'h000000000000000001000000;
                7'd75: chevron_row = 96'h000000000000000000000000;
                7'd76: chevron_row = 96'h000000000000000000000000;
                7'd77: chevron_row = 96'h000000000000000000000000;
                7'd78: chevron_row = 96'h000000000000000000000000;
                7'd79: chevron_row = 96'h000000000000000000000000;
                7'd80: chevron_row = 96'h000000000000000000000000;
                7'd81: chevron_row = 96'h000000000000000000000000;
                7'd82: chevron_row = 96'h000000000000000000000000;
                7'd83: chevron_row = 96'h000000000000000000000000;
                7'd84: chevron_row = 96'h000000000000000000000000;
                7'd85: chevron_row = 96'h000000000000000000000000;
                7'd86: chevron_row = 96'h000000000000000000000000;
                7'd87: chevron_row = 96'h000000000000000000000000;
                7'd88: chevron_row = 96'h000000000000000000000000;
                7'd89: chevron_row = 96'h000000000000000000000000;
                7'd90: chevron_row = 96'h000000000000000000000000;
                7'd91: chevron_row = 96'h000000000000000000000000;
                7'd92: chevron_row = 96'h000000000000000000000000;
                7'd93: chevron_row = 96'h000000000000000000000000;
                7'd94: chevron_row = 96'h000000000000000000000000;
                7'd95: chevron_row = 96'h000000000000000000000000;
                7'd96: chevron_row = 96'h000000000000000000000000;
                7'd97: chevron_row = 96'h000000000000000000000000;
                7'd98: chevron_row = 96'h000000000000000000000000;
                7'd99: chevron_row = 96'h000000000000000000000000;
                default: chevron_row = 96'h000000000000000000000000;
            endcase
        end
    endfunction

    wire is_chevron_pixel;
    reg [9:0] chevron_col_offset;
    reg [9:0] chevron_row_offset;
    reg [9:0] chevron_scaled_col;
    reg [9:0] chevron_scaled_row;
    reg chevron_box_hit;

    always @(*) begin
        chevron_box_hit = 1'b0;
        chevron_col_offset = 0;
        chevron_row_offset = 0;
        chevron_scaled_col = 0;
        chevron_scaled_row = 0;

        // Check if the pixel is within the chevron bounds (scaled)
        if (y >= CHEVRON_Y && y < (CHEVRON_Y + CHEVRON_HEIGHT) &&
            x >= CHEVRON_X && x < (CHEVRON_X + CHEVRON_WIDTH)) begin
            chevron_col_offset = x - CHEVRON_X;
            chevron_row_offset = y - CHEVRON_Y;
            // Scale down to original bitmap coordinates (divide by scale factor)
            chevron_scaled_col = chevron_col_offset >> 1;  // Divide by 2
            chevron_scaled_row = chevron_row_offset >> 1;  // Divide by 2
            chevron_box_hit = 1'b1;
        end
    end

    // Look up the pixel from the chevron bitmap ROM
    // Chevron is 85 pixels wide, stored in 96 bits with padding on the right
    // Bit 95 is leftmost pixel (x=0), bit 11 is rightmost pixel (x=84)
    // When scaling 2x, chevron_scaled_col ranges from 0-84, chevron_scaled_row ranges from 0-99
    wire [95:0] chevron_mask = chevron_row(chevron_scaled_row[6:0]);
    wire [6:0] chevron_bit_idx = 7'd95 - chevron_scaled_col[6:0];
    wire chevron_pixel_value = chevron_box_hit ? chevron_mask[chevron_bit_idx] : 1'b0;
    
    // Draw the chevron pixels (no border)
    assign is_chevron_pixel = chevron_pixel_value;

    function automatic [6:0] shield_width;
        input [7:0] y_addr;
        begin
            shield_width = 7'd78;

            if (y_addr < 8'd88) begin
                shield_width = (y_addr < 8'd83) ? 7'd77 : 7'd76;
            end else if (y_addr < 8'd96) begin
                shield_width = (y_addr < 8'd92) ? 7'd75 : 7'd74;
            end else if (y_addr < 8'd99) begin
                shield_width = 7'd73;
            end else if (y_addr < 8'd102) begin
                shield_width = 7'd72;
            end else if (y_addr < 8'd105) begin
                shield_width = 7'd71;
            end else if (y_addr < 8'd108) begin
                shield_width = 7'd70;
            end else if (y_addr < 8'd111) begin
                shield_width = 7'd69;
            end else if (y_addr < 8'd114) begin
                shield_width = 7'd68;
            end else if (y_addr < 8'd117) begin
                shield_width = 7'd67;
            end else if (y_addr < 8'd120) begin
                shield_width = 7'd66;
            end else if (y_addr < 8'd123) begin
                shield_width = 7'd65;
            end else if (y_addr < 8'd126) begin
                shield_width = 7'd64;
            end else if (y_addr < 8'd128) begin
                shield_width = 7'd63;
            end else if (y_addr < 8'd130) begin
                shield_width = 7'd62;
            end else if (y_addr < 8'd132) begin
                shield_width = 7'd61;
            end else if (y_addr < 8'd134) begin
                shield_width = 7'd60;
            end else if (y_addr < 8'd136) begin
                shield_width = 7'd59;
            end else if (y_addr < 8'd138) begin
                shield_width = 7'd58;
            end else if (y_addr < 8'd140) begin
                shield_width = 7'd57;
            end else if (y_addr < 8'd142) begin
                shield_width = 7'd56;
            end else if (y_addr < 8'd144) begin
                shield_width = 7'd55;
            end else if (y_addr < 8'd146) begin
                shield_width = 7'd54;
            end else if (y_addr < 8'd156) begin
                shield_width = 7'd53 - 7'(y_addr - 8'd146);
            end else begin
                shield_width = 7'd42 - 7'((y_addr - 8'd156) << 1);
            end
        end
    endfunction

    wire [9:0] abs_dx = (x >= EMBLEM_CENTER_X) ? (x - EMBLEM_CENTER_X) : (EMBLEM_CENTER_X - x);
    wire [9:0] rel_y = y - EMBLEM_Y0;

    reg draw_flag;

    always @(*) begin
        reg [6:0] half_width;
        reg [6:0] inner_half;
        reg shield_border;

        half_width = 0;
        inner_half = 0;
        shield_border = 0;
        draw_flag = 0;
        rgb = 6'b000000;

        if (active && (y >= EMBLEM_Y0) && (y < EMBLEM_Y1)) begin
            half_width = shield_width(rel_y[7:0]);
            if (abs_dx <= {3'b0, half_width}) begin
                draw_flag = 1;
                rgb = COLOR_GOLD;

                inner_half = (half_width > BORDER_THICKNESS[6:0]) ? (half_width - BORDER_THICKNESS[6:0]) : 7'b0;
                if ((abs_dx > {3'b0, inner_half}) || (rel_y < BORDER_THICKNESS)) shield_border = 1;

                if (is_chevron_pixel) rgb = COLOR_WHITE;
                if (is_lion_pixel) rgb = COLOR_RED;
                if (shield_border) rgb = COLOR_BLACK;
            end
        end
        draw = draw_flag;
    end

endmodule
