module hazard_unit (
    // --- FORWARDING INPUTS ---
    input [4:0] Rs1_E, Rs2_E,   // Source registers currently used in Execute
    
    // "M" and "W" are just labels for the Result of the previous instruction.
    // In your 3-stage pipe, they are effectively the same thing (the output of Execute).
    input [4:0] Rd_M,           
    input RegWrite_M,
    input [4:0] Rd_W,
    input RegWrite_W,

    // --- STALL INPUTS ---
    input [4:0] Rs1_D, Rs2_D,   // Source registers waiting in Decode
    input MemRead_E,            // Is the instruction in Execute a Load?
    input [4:0] Rd_E_Load,      // Destination of that Load

    // --- OUTPUTS ---
    output reg [1:0] ForwardAE, ForwardBE,
    output reg Stall_F, Stall_D, Flush_E
);

    always @(*) begin
        // ===========================
        // 1. FORWARDING LOGIC
        // ===========================
        // Checks if the previous instruction (finishing Execute) wrote to the registers
        // we need right now.
        
        // Forward A (Source 1)
        ForwardAE = 2'b00; // Default: Use Register File
        if (RegWrite_M && (Rd_M != 0) && (Rd_M == Rs1_E)) 
            ForwardAE = 2'b10; // Forward from ALU Result
        else if (RegWrite_W && (Rd_W != 0) && (Rd_W == Rs1_E))
            ForwardAE = 2'b01; // Forward from Writeback (Safety backup)

        // Forward B (Source 2)
        ForwardBE = 2'b00; // Default: Use Register File
        if (RegWrite_M && (Rd_M != 0) && (Rd_M == Rs2_E))
            ForwardBE = 2'b10; // Forward from ALU Result
        else if (RegWrite_W && (Rd_W != 0) && (Rd_W == Rs2_E))
            ForwardBE = 2'b01; // Forward from Writeback (Safety backup)

        // ===========================
        // 2. STALL LOGIC (Load-Use)
        // ===========================
        Stall_F = 0;
        Stall_D = 0;
        Flush_E = 0;

        // If the instruction in Execute is a Load (lw), the data isn't ready yet.
        // If the instruction in Decode needs that data, we must WAIT 1 cycle.
        if (MemRead_E && ((Rd_E_Load == Rs1_D) || (Rd_E_Load == Rs2_D))) begin
            Stall_F = 1; // Freeze PC
            Stall_D = 1; // Freeze Decode
            Flush_E = 1; // Clear Execute (Insert Bubble)
        end
    end

endmodule