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

    localparam [9:0] SHIELD_HEIGHT     = EMBLEM_Y1 - EMBLEM_Y0;
    localparam [9:0] BORDER_THICKNESS  = 3;
    localparam [9:0] CHEVRON_APEX         = 70;
    localparam [9:0] CHEVRON_HEIGHT       = 56;
    localparam [9:0] CHEVRON_BORDER_WIDTH = 8;
    localparam [9:0] CHEVRON_WHITE_WIDTH  = 20;
    localparam [9:0] CHEVRON_EDGE_MARGIN  = 2;
    localparam [9:0] CHEVRON_BOTTOM_Y_REL = CHEVRON_APEX + CHEVRON_HEIGHT - 1;
    localparam [9:0] CHEVRON_HEIGHT_MINUS1 = CHEVRON_HEIGHT - 1;
    localparam [19:0] CHEVRON_HEIGHT_DENOM = {{10{1'b0}}, CHEVRON_HEIGHT_MINUS1};
    localparam [19:0] CHEVRON_ROUNDING_TERM = CHEVRON_HEIGHT_DENOM >> 1;

    localparam integer LION_WIDTH_PIX  = 48;
    localparam integer LION_HEIGHT_PIX = 45;
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
                6'd0: lion_row = 48'h03F000000000;
                6'd1: lion_row = 48'h03F000000000;
                6'd2: lion_row = 48'h07FC00000000;
                6'd3: lion_row = 48'h1FFE00000000;
                6'd4: lion_row = 48'h1FFE00000000;
                6'd5: lion_row = 48'h3FFF80C00000;
                6'd6: lion_row = 48'hFFFFC1E00000;
                6'd7: lion_row = 48'hFFFFC1E00000;
                6'd8: lion_row = 48'h1FEFFFF8F000;
                6'd9: lion_row = 48'h3FE3FFFCF180;
                6'd10: lion_row = 48'h3FE3FFFCF180;
                6'd11: lion_row = 48'hFF81FFFCFF80;
                6'd12: lion_row = 48'hFF007FFC7F80;
                6'd13: lion_row = 48'hFF007FFC7F80;
                6'd14: lion_row = 48'hFC003FFC7F80;
                6'd15: lion_row = 48'hFC003FFC7F80;
                6'd16: lion_row = 48'hFC003FFC7F80;
                6'd17: lion_row = 48'hFC003FFCFF80;
                6'd18: lion_row = 48'hFF007FFCFF80;
                6'd19: lion_row = 48'hFF007FFCFF80;
                6'd20: lion_row = 48'hFFFFFFFFFFC0;
                6'd21: lion_row = 48'hFFFFF1FFFFC0;
                6'd22: lion_row = 48'hFFFFF1FFFFC0;
                6'd23: lion_row = 48'hFFFFC1FFFF80;
                6'd24: lion_row = 48'hFFFF81FFFE00;
                6'd25: lion_row = 48'hFFFF81FFFE00;
                6'd26: lion_row = 48'h3FFE00FFFC00;
                6'd27: lion_row = 48'h1FF000FFF078;
                6'd28: lion_row = 48'h1FF000FFF078;
                6'd29: lion_row = 48'h07F001FFF3F8;
                6'd30: lion_row = 48'h03FC01FFFFFF;
                6'd31: lion_row = 48'h03FC01FFFFFF;
                6'd32: lion_row = 48'h00FF81FFFFF8;
                6'd33: lion_row = 48'h007FC1FFFFF0;
                6'd34: lion_row = 48'h007FC1FFFFF0;
                6'd35: lion_row = 48'h001FC1FFFE00;
                6'd36: lion_row = 48'h000FC0FFFC00;
                6'd37: lion_row = 48'h000FC0FFFC00;
                6'd38: lion_row = 48'h0003C03FE000;
                6'd39: lion_row = 48'h0001C01F8000;
                6'd40: lion_row = 48'h0001C01F8000;
                6'd41: lion_row = 48'h000040038000;
                6'd42: lion_row = 48'h000000000000;
                6'd43: lion_row = 48'h000000000000;
                6'd44: lion_row = 48'h000000000000;
                default: lion_row = 48'h000000000000;
            endcase
        end
    endfunction

    function is_lion_pixel_with_mirror;
        input [9:0] px;
        input [9:0] py;
        input [9:0] origin_x;
        input [9:0] origin_y;
        input mirror;
        reg [9:0] row_offset;
        reg [9:0] col_offset;
        reg [9:0] row_idx_ext;
        reg [9:0] col_idx_ext;
        reg [5:0] row_idx;
        reg [5:0] col_idx_final;
        reg [LION_WIDTH_PIX-1:0] mask;
        begin
            is_lion_pixel_with_mirror = 0;
            if ((py >= origin_y) && (py < origin_y + LION_HEIGHT) && (px >= origin_x) && (px < origin_x + LION_WIDTH)) begin
                row_offset = py - origin_y;
                col_offset = px - origin_x;
                row_idx_ext = LION_HEIGHT - 1 - row_offset;
                row_idx = row_idx_ext[5:0];
                mask = lion_row(row_idx);
                if (mirror) begin
                    col_idx_ext = LION_WIDTH - 1 - col_offset;
                    col_idx_final = col_idx_ext[5:0];
                end else begin
                    col_idx_final = col_offset[5:0];
                end
                is_lion_pixel_with_mirror = mask[col_idx_final];
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
    wire top_left_lion  = is_lion_pixel_with_mirror(x, y, LEFT_LION_X, TOP_LION_Y, 0);
    wire top_right_lion = is_lion_pixel_with_mirror(x, y, RIGHT_LION_X, TOP_LION_Y, 0);
    wire bottom_lion    = is_lion_pixel_with_mirror(x, y, CENTER_LION_X, BOTTOM_LION_Y, 0);

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

                    // Draw chevron layers
                    white_outer = (outer_width > CHEVRON_BORDER_WIDTH) ? (outer_width - CHEVRON_BORDER_WIDTH) : 0;
                    white_inner = (white_outer > CHEVRON_WHITE_WIDTH) ? (white_outer - CHEVRON_WHITE_WIDTH) : 0;
                    inner_core = (white_inner > CHEVRON_BORDER_WIDTH) ? (white_inner - CHEVRON_BORDER_WIDTH) : 0;

                    if (abs_dx <= outer_width) begin
                        if (abs_dx >= white_outer) chevron_border = 1;
                        else if (abs_dx >= white_inner) chevron_fill = 1;
                        else if (abs_dx >= inner_core) chevron_border = 1;
                        // else: center remains gold (default color_sel)
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
