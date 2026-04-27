	module lsfr_24_bit_design (
    input logic clk,enable,rst, // reset is active low
    output logic [23:0]data_out
  );

  parameter SEED = 24'h000001;

  logic [23:0] lsfr ;
  logic feedback ;

  assign feedback = lsfr[23]^lsfr[22]^lsfr[21]^lsfr[16];

  always_ff @(posedge clk or negedge rst)
  begin

    if (!rst)
    begin
      lsfr <= SEED;
    end

    else
    begin
      if (enable)
      begin
        lsfr <= {lsfr[22:0],feedback};
      end


    end
  end

  assign data_out = lsfr;

endmodule

