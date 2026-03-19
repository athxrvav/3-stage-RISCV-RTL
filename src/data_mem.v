module data_mem (
    input clk,
    input we,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd
);

    reg [31:0] mem [0:4095];
    integer i;

    // -- ---
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
    end
    // ---------

    // READ LOGIC
    assign rd = mem[addr[13:2]];

    // WRITE LOGIC
    always @(posedge clk) begin
        if (we) begin
            mem[addr[13:2]] <= wd;
        end
    end

endmodule