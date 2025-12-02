module emblem_gen(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    output reg [5:0] rgb
);

    localparam [5:0] COLOR_TRANSPARENT = 6'b100001;
    localparam [5:0] COLOR_BLACK = 6'b000000;
    localparam [5:0] COLOR_GOLD = 6'b110110;
    localparam [5:0] COLOR_RED = 6'b100100;
    localparam [5:0] COLOR_WHITE = 6'b111111;

    // Chevron parameters (original bitmap: 85x100, scaled 2x for display)
    localparam [9:0] CHEV_X = 235;
    localparam [9:0] CHEV_Y = 200;

    localparam [9:0] LION_W = 48;
    localparam [9:0] LION_H = 45;
    localparam [9:0] TOP_LION_Y = 160; // 144 + 16
    localparam [9:0] BOT_LION_Y = 264; // 144 + 120
    localparam [9:0] LEFT_LION_X = 260; // 320 - 80 + 20
    localparam [9:0] RIGHT_LION_X = 332; // 320 + 80 - 20 - 48
    localparam [9:0] CENTER_LION_X = 296; // 320 - 24

    function automatic [47:0] lion_row;
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
                6'd13, 6'd14: lion_row = 48'h3F33FFFFFF80; // Reused for rows 13 and 14
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
                6'd33, 6'd34, 6'd35: lion_row = 48'h0007FEFF0000; // Reused for rows 33, 34, and 35
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

    reg [5:0] lion_col_offset;
    reg [5:0] lion_row_offset;
    reg lion_box_hit;

    always @(*) begin
        lion_box_hit = 0;
        lion_col_offset = 0;
        lion_row_offset = 0;

        /* verilator lint_off WIDTH */

        // Check top lions (same Y range, two possible X ranges)
        if (y >= TOP_LION_Y && y < (TOP_LION_Y + LION_H)) begin
            lion_row_offset = y - TOP_LION_Y;
            if (x >= LEFT_LION_X && x < (LEFT_LION_X + LION_W)) begin
                lion_col_offset = x - LEFT_LION_X;
                lion_box_hit = 1;
            end else if (x >= RIGHT_LION_X && x < (RIGHT_LION_X + LION_W)) begin
                lion_col_offset = x - RIGHT_LION_X;
                lion_box_hit = 1;
            end
        // Check bottom lion (one X range, one Y range)
        end else if (y >= BOT_LION_Y && y < (BOT_LION_Y + LION_H) && x >= CENTER_LION_X && x < (CENTER_LION_X + LION_W)) begin
            lion_col_offset = x - CENTER_LION_X;
            lion_row_offset = y - BOT_LION_Y;
            lion_box_hit = 1;
        end
        /* verilator lint_on WIDTH */
    end

    wire [47:0] lion_row_data = lion_row(lion_row_offset);
    wire is_lion_pixel = lion_box_hit && lion_row_data[lion_col_offset];

    // Original bitmap data retained for the white chevron.
    function automatic [95:0] chevron_row;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  chevron_row = 96'h000000000020000000000000;
                6'd1:  chevron_row = 96'h000000000070000000000000;
                6'd2:  chevron_row = 96'h0000000000F8000000000000;
                6'd3:  chevron_row = 96'h0000000001FC000000000000;
                6'd4:  chevron_row = 96'h0000000003FE000000000000;
                6'd5:  chevron_row = 96'h0000000007FF000000000000;
                6'd6:  chevron_row = 96'h000000000FFF800000000000;
                6'd7:  chevron_row = 96'h000000001FFFC00000000000;
                6'd8:  chevron_row = 96'h000000003FFFE00000000000;
                6'd9:  chevron_row = 96'h000000007FFFF00000000000;
                6'd10: chevron_row = 96'h00000000FFDFF80000000000;
                6'd11: chevron_row = 96'h00000001FF8FFC0000000000;
                6'd12: chevron_row = 96'h00000003FF07FE0000000000;
                6'd13: chevron_row = 96'h00000007FE03FF0000000000;
                6'd14: chevron_row = 96'h0000000FFC01FF8000000000;
                6'd15: chevron_row = 96'h0000001FF800FFC000000000;
                6'd16: chevron_row = 96'h0000003FF0007FE000000000;
                6'd17: chevron_row = 96'h0000007FE0003FF000000000;
                6'd18: chevron_row = 96'h000000FFC0001FF800000000;
                6'd19: chevron_row = 96'h000001FF80000FFC00000000;
                6'd20: chevron_row = 96'h000003FF000007FE00000000;
                6'd21: chevron_row = 96'h000007FE000003FF00000000;
                6'd22: chevron_row = 96'h00000FFC000001FF80000000;
                6'd23: chevron_row = 96'h00001FF8000000FFC0000000;
                6'd24: chevron_row = 96'h00003FF00000007FE0000000;
                6'd25: chevron_row = 96'h00007FE00000003FF0000000;
                6'd26: chevron_row = 96'h0000FFC00000001FF8000000;
                6'd27: chevron_row = 96'h0001FF800000000FFC000000;
                6'd28: chevron_row = 96'h0003FF0000000007FE000000;
                6'd29: chevron_row = 96'h0007FE0000000003FF000000;
                6'd30: chevron_row = 96'h000FFC0000000001FF800000;
                6'd31: chevron_row = 96'h001FF80000000000FFC00000;
                6'd32: chevron_row = 96'h003FF000000000007FE00000;
                6'd33: chevron_row = 96'h001FE000000000003FC00000;
                6'd34: chevron_row = 96'h000FC000000000001F800000;
                6'd35: chevron_row = 96'h000F8000000000000F800000;
                6'd36: chevron_row = 96'h000F00000000000007800000;
                6'd37: chevron_row = 96'h000E00000000000003800000;
                6'd38: chevron_row = 96'h000C00000000000001800000;
                6'd39: chevron_row = 96'h000800000000000000800000;
                default: chevron_row = 96'h000000000000000000000000;
            endcase
        end
    endfunction

    function automatic [95:0] chevron_row_black;
        input [5:0] idx;
        reg [95:0] raw_row;
        begin
            raw_row = chevron_row(idx);
            
            chevron_row_black = (~raw_row) & ({1'b0, raw_row[95:1]} | {raw_row[94:0], 1'b0});
        end
    endfunction

    /* verilator lint_off WIDTH */
    wire [6:0] chevron_scaled_col = (x - CHEV_X) >> 1;
    wire [5:0] chevron_scaled_row = (y - CHEV_Y) >> 1;
    /* verilator lint_on WIDTH */

    /* verilator lint_off WIDTHTRUNC */
    wire chevron_window = y >= CHEV_Y && y < (CHEV_Y + 80) && x >= CHEV_X && x < (CHEV_X + 170);
    wire [95:0] chevron_row_white_data = chevron_row(chevron_scaled_row);
    wire [95:0] chevron_row_black_data = chevron_row_black(chevron_scaled_row);
    wire is_chevron_white_pixel = chevron_window && chevron_row_white_data[95 - chevron_scaled_col];
    wire is_chevron_black_pixel = chevron_window && chevron_row_black_data[95 - chevron_scaled_col];
    /* verilator lint_on WIDTHTRUNC */

    function automatic [6:0] shield_width;
        input [7:0] y_addr;
        begin
            if (y_addr < 8'd83) shield_width = 7'd77;
            else if (y_addr < 8'd88) shield_width = 7'd76;
            else if (y_addr < 8'd92) shield_width = 7'd75;
            else if (y_addr < 8'd96) shield_width = 7'd74;
            else if (y_addr < 8'd99) shield_width = 7'd73;
            else if (y_addr < 8'd102) shield_width = 7'd72;
            else if (y_addr < 8'd105) shield_width = 7'd71;
            else if (y_addr < 8'd108) shield_width = 7'd70;
            else if (y_addr < 8'd111) shield_width = 7'd69;
            else if (y_addr < 8'd114) shield_width = 7'd68;
            else if (y_addr < 8'd117) shield_width = 7'd67;
            else if (y_addr < 8'd120) shield_width = 7'd66;
            else if (y_addr < 8'd123) shield_width = 7'd65;
            else if (y_addr < 8'd126) shield_width = 7'd64;
            else if (y_addr < 8'd128) shield_width = 7'd63;
            else if (y_addr < 8'd130) shield_width = 7'd62;
            else if (y_addr < 8'd132) shield_width = 7'd61;
            else if (y_addr < 8'd134) shield_width = 7'd60;
            else if (y_addr < 8'd136) shield_width = 7'd59;
            else if (y_addr < 8'd138) shield_width = 7'd58;
            else if (y_addr < 8'd140) shield_width = 7'd57;
            else if (y_addr < 8'd142) shield_width = 7'd56;
            else if (y_addr < 8'd144) shield_width = 7'd55;
            else if (y_addr < 8'd146) shield_width = 7'd54;
            else if (y_addr < 8'd156) shield_width = 7'd53 - 7'(y_addr - 8'd146);
            else shield_width = 7'd42 - 7'((y_addr - 8'd156) << 1);
        end
    endfunction

    always @(*) begin
        reg [6:0] half_width;
        reg [6:0] border_inner;
        reg [9:0] abs_dx;
        reg [9:0] rel_y;

        abs_dx = (x >= 320) ? (x - 320) : (320 - x);
        rel_y = y - 144;
        half_width = shield_width(rel_y[7:0]);
        border_inner = (half_width > 3) ? (half_width - 3) : 7'd0;
        rgb = COLOR_TRANSPARENT;

        if (active && y >= 144 && y < 320 && abs_dx <= {3'b0, half_width}) begin
            rgb = COLOR_GOLD;
            if (is_chevron_white_pixel) rgb = COLOR_WHITE;
            if (is_chevron_black_pixel) rgb = COLOR_BLACK;
            if (is_lion_pixel) rgb = COLOR_RED;
            // Border is either outer 3 pixels or top 3 rows
            if (abs_dx > {3'b0, border_inner} || rel_y < 3) rgb = COLOR_BLACK;
        end
    end

endmodule
