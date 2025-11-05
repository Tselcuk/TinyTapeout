/* Text Overlay Generator
 *
 * The foreground text is stored as run-length encoded segments per scanline.
 * Each VGA pixel evaluates a small number of range checks instead of pulling
 * from a wide bitmap, keeping the combinational path short enough for timing.
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

    localparam [9:0] TEXT_LINE0_POS_X = 10'd256;
    localparam [9:0] TEXT_LINE1_POS_X = 10'd232;
    localparam [9:0] TARGET_LINE0_Y0  = 10'd336;
    localparam [9:0] FALL_START_Y0    = 10'd0;
    localparam [9:0] FALL_STEP_PX     = 10'd4;
    localparam [9:0] CHAR_HEIGHT_PX   = 10'd16;
    localparam [9:0] LINE_GAP_PX      = 10'd4;
    localparam [9:0] LINE0_WIDTH_PX   = 10'd128;
    localparam [9:0] LINE1_WIDTH_PX   = 10'd176;
    localparam [5:0] COLOR_TEXT       = 6'b111111;

    // Run-length encoded segments for each scanline (16 rows per line).

    reg [9:0] drop_y;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            drop_y <= FALL_START_Y0;
        end else begin
            if (next_frame && (drop_y < TARGET_LINE0_Y0)) begin
                if (drop_y + FALL_STEP_PX >= TARGET_LINE0_Y0) begin
                    drop_y <= TARGET_LINE0_Y0;
                end else begin
                    drop_y <= drop_y + FALL_STEP_PX;
                end
            end
        end
    end

    wire [9:0] line0_y0 = drop_y;
    wire [9:0] line0_y1 = drop_y + CHAR_HEIGHT_PX;
    wire [9:0] line1_y0_ext = drop_y + CHAR_HEIGHT_PX + LINE_GAP_PX;
    wire [9:0] line1_y0 = line1_y0_ext;
    wire [9:0] line1_y1 = line1_y0 + CHAR_HEIGHT_PX;

    function [0:0] line0_pixel(input [3:0] row, input [9:0] x_rel);
        reg hit;
        case (row)
            4'd0: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd20) && (x_rel <= 10'd27)) || ((x_rel >= 10'd34) && (x_rel <= 10'd45)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd100) && (x_rel <= 10'd107)) || ((x_rel >= 10'd116) && (x_rel <= 10'd123));
            4'd1: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd20) && (x_rel <= 10'd27)) || ((x_rel >= 10'd34) && (x_rel <= 10'd45)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd100) && (x_rel <= 10'd107)) || ((x_rel >= 10'd116) && (x_rel <= 10'd123));
            4'd2: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd3: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd4: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd5: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd6: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd6) && (x_rel <= 10'd9)) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd59)) || ((x_rel >= 10'd66) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd7: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd6) && (x_rel <= 10'd9)) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd59)) || ((x_rel >= 10'd66) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd8: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd4) && (x_rel <= 10'd5)) || ((x_rel >= 10'd10) && (x_rel <= 10'd11)) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd72) && (x_rel <= 10'd73)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd9: hit = (x_rel <= 10'd1) || ((x_rel >= 10'd4) && (x_rel <= 10'd5)) || ((x_rel >= 10'd10) && (x_rel <= 10'd11)) || ((x_rel >= 10'd14) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd72) && (x_rel <= 10'd73)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd10: hit = (x_rel <= 10'd3) || ((x_rel >= 10'd12) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd74) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd11: hit = (x_rel <= 10'd3) || ((x_rel >= 10'd12) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd51)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd74) && (x_rel <= 10'd75)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd108) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125));
            4'd12: hit = (x_rel <= 10'd3) || ((x_rel >= 10'd12) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd100) && (x_rel <= 10'd107)) || ((x_rel >= 10'd116) && (x_rel <= 10'd123));
            4'd13: hit = (x_rel <= 10'd3) || ((x_rel >= 10'd12) && (x_rel <= 10'd15)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd38) && (x_rel <= 10'd41)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd100) && (x_rel <= 10'd107)) || ((x_rel >= 10'd116) && (x_rel <= 10'd123));
            default: hit = 1'b0;
        endcase
        line0_pixel = hit;
    endfunction

    function [0:0] line1_pixel(input [3:0] row, input [9:0] x_rel);
        reg hit;
        case (row)
            4'd0: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd13)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd36) && (x_rel <= 10'd43)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd98) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd123)) || ((x_rel >= 10'd130) && (x_rel <= 10'd141)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd164) && (x_rel <= 10'd171));
            4'd1: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd13)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd36) && (x_rel <= 10'd43)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd98) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd123)) || ((x_rel >= 10'd130) && (x_rel <= 10'd141)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd164) && (x_rel <= 10'd171));
            4'd2: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd21)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd69)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd149)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd3: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd21)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd69)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd149)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd4: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd22) && (x_rel <= 10'd23)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd70) && (x_rel <= 10'd71)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd150) && (x_rel <= 10'd151)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163));
            4'd5: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd22) && (x_rel <= 10'd23)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd70) && (x_rel <= 10'd71)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd150) && (x_rel <= 10'd151)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163));
            4'd6: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd11)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd24) && (x_rel <= 10'd25)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd40) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd72) && (x_rel <= 10'd73)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd91)) || ((x_rel >= 10'd98) && (x_rel <= 10'd107)) || ((x_rel >= 10'd114) && (x_rel <= 10'd123)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd152) && (x_rel <= 10'd153)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd168) && (x_rel <= 10'd173));
            4'd7: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd11)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd24) && (x_rel <= 10'd25)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd40) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd72) && (x_rel <= 10'd73)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd91)) || ((x_rel >= 10'd98) && (x_rel <= 10'd107)) || ((x_rel >= 10'd114) && (x_rel <= 10'd123)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd152) && (x_rel <= 10'd153)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd168) && (x_rel <= 10'd173));
            4'd8: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd26) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd74) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd120) && (x_rel <= 10'd121)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd154) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd9: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd26) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd74) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd120) && (x_rel <= 10'd121)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd154) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd10: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd122) && (x_rel <= 10'd123)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd11: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd3)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd34) && (x_rel <= 10'd35)) || ((x_rel >= 10'd44) && (x_rel <= 10'd45)) || ((x_rel >= 10'd54) && (x_rel <= 10'd57)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd83)) || ((x_rel >= 10'd98) && (x_rel <= 10'd99)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd122) && (x_rel <= 10'd123)) || ((x_rel >= 10'd134) && (x_rel <= 10'd137)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd162) && (x_rel <= 10'd163)) || ((x_rel >= 10'd172) && (x_rel <= 10'd173));
            4'd12: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd13)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd36) && (x_rel <= 10'd43)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd98) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd130) && (x_rel <= 10'd141)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd164) && (x_rel <= 10'd171));
            4'd13: hit = ((x_rel >= 10'd2) && (x_rel <= 10'd13)) || ((x_rel >= 10'd18) && (x_rel <= 10'd19)) || ((x_rel >= 10'd28) && (x_rel <= 10'd29)) || ((x_rel >= 10'd36) && (x_rel <= 10'd43)) || ((x_rel >= 10'd50) && (x_rel <= 10'd61)) || ((x_rel >= 10'd66) && (x_rel <= 10'd67)) || ((x_rel >= 10'd76) && (x_rel <= 10'd77)) || ((x_rel >= 10'd82) && (x_rel <= 10'd93)) || ((x_rel >= 10'd98) && (x_rel <= 10'd109)) || ((x_rel >= 10'd114) && (x_rel <= 10'd115)) || ((x_rel >= 10'd124) && (x_rel <= 10'd125)) || ((x_rel >= 10'd130) && (x_rel <= 10'd141)) || ((x_rel >= 10'd146) && (x_rel <= 10'd147)) || ((x_rel >= 10'd156) && (x_rel <= 10'd157)) || ((x_rel >= 10'd164) && (x_rel <= 10'd171));
            default: hit = 1'b0;
        endcase
        line1_pixel = hit;
    endfunction

    always @(*) begin
        reg [9:0] x_rel0;
        reg [9:0] x_rel1;
        reg [3:0] row0;
        reg [3:0] row1;
        reg [3:0] y_rel0;
        reg [3:0] y_rel1;
        reg [3:0] y_rel0_temp;
        reg [3:0] y_rel1_temp;
        reg [9:0] y_rel0_full;
        reg [9:0] y_rel1_full;

        draw = 0;
        rgb  = 0;
        x_rel0 = 0;
        x_rel1 = 0;
        row0   = 0;
        row1   = 0;
        y_rel0 = 0;
        y_rel1 = 0;
        y_rel0_temp = 0;
        y_rel1_temp = 0;
        y_rel0_full = 0;
        y_rel1_full = 0;

        if (active) begin
            if ((y >= line0_y0) && (y < line0_y1) &&
                (x >= TEXT_LINE0_POS_X) && (x < TEXT_LINE0_POS_X + LINE0_WIDTH_PX)) begin
                x_rel0 = x - TEXT_LINE0_POS_X;
                y_rel0_full = y - line0_y0;
                y_rel0_temp = y_rel0_full[3:0];
                y_rel0 = y_rel0_temp;
                row0   = y_rel0;
                if (line0_pixel(row0, x_rel0)) begin
                    draw = 1;
                end
            end else if ((y >= line1_y0) && (y < line1_y1) &&
                         (x >= TEXT_LINE1_POS_X) && (x < TEXT_LINE1_POS_X + LINE1_WIDTH_PX)) begin
                x_rel1 = x - TEXT_LINE1_POS_X;
                y_rel1_full = y - line1_y0;
                y_rel1_temp = y_rel1_full[3:0];
                y_rel1 = y_rel1_temp;
                row1   = y_rel1;
                if (line1_pixel(row1, x_rel1)) begin
                    draw = 1;
                end
            end
        end

        if (draw) begin
            rgb = {
                COLOR_TEXT[5],
                COLOR_TEXT[3],
                COLOR_TEXT[1],
                COLOR_TEXT[4],
                COLOR_TEXT[2],
                COLOR_TEXT[0]
            };
        end
    end

endmodule
