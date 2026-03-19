
module reg_file(
    input clk,                   // System Clock
    input we,                    // Write Enable (High = Write, Low = Read Only)
    input [4:0] ra1,             // Read Address 1 (5 bits selects 0-31)
    input [4:0] ra2,             // Read Address 2
    input [4:0] wa,              // Write Address
    input [31:0] wd,             // Write Data (Data to be saved)
    output [31:0] rd1,           // Read Data 1 Output
    output [31:0] rd2            // Read Data 2 Output
    );

    // The Storage: 32 registers of 32 bits each
    reg [31:0] regs [0:31];
    
    integer i;

    // Initialize all registers to 0 for simulation 
    initial begin
        for (i=0; i<32; i=i+1)
            regs[i] = 32'd0;
    end

    // --- READ OPERATION (Asynchronous / Combinational) ---
    // Reads happen immediately. If address is 0, ALWAYS output 0.
    assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];

    // --- WRITE OPERATION (Synchronous / Clocked) ---
    // Writes happen only on the rising edge of the clock.
    // We strictly prevent writing to register 0.
    always @(posedge clk) begin
        if (we && (wa != 5'd0)) begin
            regs[wa] <= wd;
        end
    end

endmodule