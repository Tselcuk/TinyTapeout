/* Emblem Overlay Generator
 *
 * Produces a stylised Waterloo shield that sits between the animated pattern
 * background and the text foreground layers.
 */
module emblem_gen (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active,
    output reg        draw,
    output reg  [5:0] rgb
);

    localparam [9:0] EMBLEM_X0 = 240;
    localparam [9:0] EMBLEM_X1 = 400;
    localparam [9:0] EMBLEM_Y0 = 144;
    localparam [9:0] EMBLEM_Y1 = 304;
    localparam [9:0] EMBLEM_CENTER_X = (EMBLEM_X0 + EMBLEM_X1) >> 1;
    localparam [9:0] HALF_WIDTH = (EMBLEM_X1 - EMBLEM_X0) >> 1;

    localparam [5:0] COLOR_BORDER = 6'b000000;
    localparam [5:0] COLOR_GOLD   = 6'b111100;
    localparam [5:0] COLOR_WHITE  = 6'b111111;
    localparam [5:0] COLOR_RED    = 6'b110000;

    localparam [9:0] BORDER_THICKNESS  = 3;
    localparam [9:0] CHEVRON_APEX         = 56;
    localparam [9:0] CHEVRON_HEIGHT       = 56;
    localparam [9:0] CHEVRON_BORDER_WIDTH = 8;
    localparam [9:0] CHEVRON_WHITE_WIDTH  = 20;
    localparam [9:0] CHEVRON_EDGE_MARGIN  = 0;
    localparam [9:0] CHEVRON_BOTTOM_Y_REL = CHEVRON_APEX + CHEVRON_HEIGHT - 1;
    localparam [9:0] CHEVRON_HEIGHT_MINUS1 = CHEVRON_HEIGHT - 1;
    localparam [19:0] CHEVRON_HEIGHT_DENOM = {{10{1'b0}}, CHEVRON_HEIGHT_MINUS1};
    localparam [19:0] CHEVRON_ROUNDING_TERM = CHEVRON_HEIGHT_DENOM >> 1;

    localparam integer LION_WIDTH_PIX  = 48;
    localparam [9:0] LION_WIDTH        = 48;
    localparam [9:0] LION_HEIGHT       = 45;
    localparam [9:0] TOP_LION_Y        = EMBLEM_Y0 + 16;
    localparam [9:0] BOTTOM_LION_Y     = EMBLEM_Y0 + 112;
    localparam [9:0] LEFT_LION_X       = EMBLEM_X0 + 20;
    localparam [9:0] RIGHT_LION_X      = EMBLEM_X1 - 20 - LION_WIDTH;
    localparam [9:0] CENTER_LION_X     = EMBLEM_CENTER_X - (LION_WIDTH >> 1);

    function [LION_WIDTH_PIX-1:0] lion_row;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  lion_row = 48'h000000380000;
                6'd1:  lion_row = 48'h000003F80000;
                6'd2:  lion_row = 48'h000007FF0004;
                6'd3:  lion_row = 48'h00000FFF404C;
                6'd4:  lion_row = 48'h07003FFF805C;
                6'd5:  lion_row = 48'h1F833FFF81FC;
                6'd6:  lion_row = 48'h3F831FFFE3FC;
                6'd7:  lion_row = 48'h1F8399FF87F8;
                6'd8:  lion_row = 48'h3FC3FFFF8FF8;
                6'd9:  lion_row = 48'h7FE003FFCFF0;
                6'd10: lion_row = 48'h0FF80FFFEF80;
                6'd11: lion_row = 48'h1FFD33FF8F0C;
                6'd12: lion_row = 48'h09FFFFFF8E0C;
                6'd13: lion_row = 48'h01FFFFFFCCFC;
                6'd14: lion_row = 48'h01FFFFFFCCFC;
                6'd15: lion_row = 48'h00FFFFFE07F8;
                6'd16: lion_row = 48'h00BFFFFE07F0;
                6'd17: lion_row = 48'h001FFFFF03C0;
                6'd18: lion_row = 48'h003FFFF8018C;
                6'd19: lion_row = 48'h003FFFFC019C;
                6'd20: lion_row = 48'h007FFFFC00FC;
                6'd21: lion_row = 48'h01F7FFF400F8;
                6'd22: lion_row = 48'h3FFE03FC0070;
                6'd23: lion_row = 48'h7FFFFFFF0070;
                6'd24: lion_row = 48'h3FFFFFFF8030;
                6'd25: lion_row = 48'hFFFFFFFFE030;
                6'd26: lion_row = 48'hFFF25FFFF010;
                6'd27: lion_row = 48'h3F11007FF810;
                6'd28: lion_row = 48'h1F0001FFFC30;
                6'd29: lion_row = 48'h1A001FFFFC30;
                6'd30: lion_row = 48'h00007FFFF8E0;
                6'd31: lion_row = 48'h00007FFFFFC0;
                6'd32: lion_row = 48'h0000FFFFFC00;
                6'd33: lion_row = 48'h0000FF7FE000;
                6'd34: lion_row = 48'h0000FF7FE000;
                6'd35: lion_row = 48'h0000FF7FE000;
                6'd36: lion_row = 48'h0000FE7FFE00;
                6'd37: lion_row = 48'h0031FE3FFF00;
                6'd38: lion_row = 48'h007BFE07FF80;
                6'd39: lion_row = 48'h007FFC02FF80;
                6'd40: lion_row = 48'h00FFD800FF80;
                6'd41: lion_row = 48'h01FF9000FF80;
                6'd42: lion_row = 48'h007E0000FF00;
                6'd43: lion_row = 48'h007E0031FC00;
                6'd44: lion_row = 48'h0046003FE800;
                default: lion_row = 48'h000000000000;
            endcase
        end
    endfunction

    function is_lion_pixel;
        input [9:0] px;
        input [9:0] py;
        input [9:0] origin_x;
        input [9:0] origin_y;
        reg [9:0] col_offset;
        reg [5:0] row_idx;
        reg [5:0] col_idx;
        reg [LION_WIDTH_PIX-1:0] mask;
        begin
            is_lion_pixel = 0;
            if ((py >= origin_y) && (py < origin_y + LION_HEIGHT) && (px >= origin_x) && (px < origin_x + LION_WIDTH)) begin
                col_offset = px - origin_x;
                /* verilator lint_off WIDTH */
                row_idx = py - origin_y;
                /* verilator lint_on WIDTH */
                mask = lion_row(row_idx);
                // Flip horizontally: mirror column index
                /* verilator lint_off WIDTH */
                col_idx = LION_WIDTH - 1 - col_offset;
                /* verilator lint_on WIDTH */
                is_lion_pixel = mask[col_idx];
            end
        end
    endfunction

    function automatic [9:0] shield_half_width;
        input [9:0] y_rel;
        reg [9:0] width;
        reg [9:0] dy;
        reg [19:0] dy_sq;
        reg [19:0] taper_ext;
        reg [9:0] taper;
        begin
            if (y_rel <= 48) begin
                width = HALF_WIDTH - 2;
            end else if (y_rel <= 120) begin
                dy = y_rel - 48;
                width = HALF_WIDTH - 2 - (dy / 6);
            end else begin
                dy = y_rel - 120;
                if (dy > 40) dy = 40;
                dy_sq = dy * dy;
                taper_ext = dy_sq >> 5;
                if (taper_ext > 66) taper = 66;
                else taper = taper_ext[9:0];
                width = 66 - taper;
            end
            if (width > HALF_WIDTH) width = HALF_WIDTH;
            if (width < 4) width = 4;
            shield_half_width = width;
        end
    endfunction

    wire [9:0] abs_dx = (x >= EMBLEM_CENTER_X) ? (x - EMBLEM_CENTER_X) : (EMBLEM_CENTER_X - x);
    wire [9:0] rel_y = y - EMBLEM_Y0;
    wire top_left_lion  = is_lion_pixel(x, y, LEFT_LION_X, TOP_LION_Y);
    wire top_right_lion = is_lion_pixel(x, y, RIGHT_LION_X, TOP_LION_Y);
    wire bottom_lion    = is_lion_pixel(x, y, CENTER_LION_X, BOTTOM_LION_Y);

    reg [5:0] color_sel;
    reg draw_flag;

    always @(*) begin
        reg [9:0] half_width;
        reg [9:0] inner_half;
        reg [9:0] chevron_dy;
        reg [9:0] outer_width;
        reg [9:0] white_outer;
        reg [9:0] white_inner;
        reg [9:0] inner_core;
        reg [9:0] chevron_bottom_half;
        reg [9:0] chevron_width_limit;
        reg [19:0] scaled_outer;
        reg [19:0] outer_width_ext;
        reg [9:0] border_outer;
        reg [9:0] border_inner;
        reg [9:0] border_core;
        reg shield_border;
        reg chevron_border;
        reg chevron_fill;

        half_width = 0;
        inner_half = 0;
        chevron_dy = 0;
        outer_width = 0;
        white_outer = 0;
        white_inner = 0;
        inner_core = 0;
        chevron_bottom_half = 0;
        chevron_width_limit = 0;
        scaled_outer = 0;
        outer_width_ext = 0;
        border_outer = 0;
        border_inner = 0;
        border_core = 0;
        shield_border = 0;
        chevron_border = 0;
        chevron_fill = 0;
        draw_flag = 0;
        color_sel = 6'b000000;

        if (active && (y >= EMBLEM_Y0) && (y < EMBLEM_Y1)) begin
            half_width = shield_half_width(rel_y);
            if (abs_dx <= half_width) begin
                draw_flag = 1;
                color_sel = COLOR_GOLD;

                inner_half = (half_width > BORDER_THICKNESS) ? (half_width - BORDER_THICKNESS) : 0;
                if ((abs_dx > inner_half) || (rel_y < BORDER_THICKNESS)) shield_border = 1;

                // Chevron drawing: triangular shape that widens as you go down
                if ((rel_y >= CHEVRON_APEX) && (rel_y <= CHEVRON_BOTTOM_Y_REL)) begin
                    chevron_dy = rel_y - CHEVRON_APEX;
                    // Calculate the width of the chevron at this y position
                    chevron_bottom_half = shield_half_width(CHEVRON_BOTTOM_Y_REL);
                    outer_width = 0;
                    if (chevron_bottom_half > CHEVRON_EDGE_MARGIN) begin
                        chevron_width_limit = chevron_bottom_half - CHEVRON_EDGE_MARGIN;
                        scaled_outer = chevron_width_limit * chevron_dy;
                        outer_width_ext = scaled_outer + CHEVRON_ROUNDING_TERM;
                        if (CHEVRON_HEIGHT_DENOM > 0) begin
                        outer_width_ext = outer_width_ext / CHEVRON_HEIGHT_DENOM;
                        end else begin
                            outer_width_ext = 1023; // Max width to indicate error
                        end
                        if (outer_width_ext > 1023) outer_width = 1023;
                        else outer_width = outer_width_ext[9:0];
                    end

                    if (outer_width > half_width) outer_width = half_width;

                    // Draw chevron layers - extend white and black lines to shield border
                    white_outer = (outer_width > CHEVRON_BORDER_WIDTH) ? (outer_width - CHEVRON_BORDER_WIDTH) : 0;
                    white_inner = (white_outer > CHEVRON_WHITE_WIDTH) ? (white_outer - CHEVRON_WHITE_WIDTH) : 0;
                    inner_core = (white_inner > CHEVRON_BORDER_WIDTH) ? (white_inner - CHEVRON_BORDER_WIDTH) : 0;

                    // Extend borders to shield edge
                    if (abs_dx <= half_width) begin
                        if (abs_dx <= outer_width) begin
                            // Inside chevron shape
                            if (abs_dx >= white_outer) chevron_border = 1;
                            else if (abs_dx >= white_inner) chevron_fill = 1;
                            else if (abs_dx >= inner_core) chevron_border = 1;
                            // else: center remains gold (default color_sel)
                        end else begin
                            // Extend border lines beyond chevron to shield edge
                            // Calculate which border zone we're in
                            if (half_width > CHEVRON_BORDER_WIDTH) begin
                                border_outer = half_width - CHEVRON_BORDER_WIDTH;
                                if (abs_dx >= border_outer) chevron_border = 1;
                                else if (border_outer > CHEVRON_WHITE_WIDTH) begin
                                    border_inner = border_outer - CHEVRON_WHITE_WIDTH;
                                    if (abs_dx >= border_inner && border_inner > CHEVRON_BORDER_WIDTH) begin
                                        border_core = border_inner - CHEVRON_BORDER_WIDTH;
                                        if (abs_dx >= border_core) chevron_border = 1;
                                        else chevron_fill = 1;
                                    end else if (abs_dx >= border_inner) begin
                                        chevron_fill = 1;
                                    end
                                end
                            end
                        end
                    end
                end

                // Apply chevron colors (but keep gold as default for center)
                if (chevron_fill) color_sel = COLOR_WHITE;
                else if (chevron_border) color_sel = COLOR_BORDER;
                // If neither chevron_fill nor chevron_border, color_sel stays COLOR_GOLD
                if (top_left_lion || top_right_lion || bottom_lion) color_sel = COLOR_RED;
                if (shield_border) color_sel = COLOR_BORDER;
            end
        end
        draw = draw_flag;
    end

    always @(*) begin
        rgb = {color_sel[5], color_sel[3], color_sel[1], color_sel[4], color_sel[2], color_sel[0]};
    end

endmodule
