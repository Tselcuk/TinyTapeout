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
    localparam [9:0] HALF_WIDTH = (EMBLEM_X1 - EMBLEM_X0) >> 1;

    localparam [5:0] COLOR_BLACK = 6'b000000;
    localparam [5:0] COLOR_GOLD = 6'b110110;
    localparam [5:0] COLOR_RED = 6'b100100;

    localparam [9:0] BORDER_THICKNESS = 3;

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
    assign is_lion_pixel = lion_box_hit ? lion_row(lion_row_offset[5:0])[lion_col_offset[5:0]] : 1'b0;

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

                if (is_lion_pixel) rgb = COLOR_RED;
                if (shield_border) rgb = COLOR_BLACK;
            end
        end
        draw = draw_flag;
    end

endmodule
