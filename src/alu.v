`timescale 1ns / 1ps

module alu(
    input signed [31:0] A,       // Input A 
    input signed [31:0] B,       // Input B
    input [3:0] ALU_Sel,         // Control Signal
    output reg [31:0] ALU_Out,   // Result
    output Zero                  // Zero Flag
    );

    // --- 1. DEFINE PARAMETERS ---
    // Arithmetic
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b1000;
    
    // Logic
    localparam ALU_AND  = 4'b0111;
    localparam ALU_OR   = 4'b0110;
    localparam ALU_XOR  = 4'b0100;
    
    // Shifts
    localparam ALU_SLL  = 4'b0001; // Shift Left Logical
    localparam ALU_SRL  = 4'b0101; // Shift Right Logical
    localparam ALU_SRA  = 4'b1101; // Shift Right Arithmetic
    
    // Comparisons
    localparam ALU_SLT  = 4'b0010; // Set Less Than (Signed)
    localparam ALU_SLTU = 4'b0011; // Set Less Than (Unsigned)


    // --- 2. ASSIGN OUTPUTS ---
    assign Zero = (ALU_Out == 0);

    always @(*) begin
        case(ALU_Sel)
            // Arithmetic
            ALU_ADD:  ALU_Out = A + B;
            ALU_SUB:  ALU_Out = A - B;
            
            // Logic
            ALU_AND:  ALU_Out = A & B;
            ALU_OR:   ALU_Out = A | B;
            ALU_XOR:  ALU_Out = A ^ B;
            
            // Shifts
            ALU_SLL:  ALU_Out = A << B[4:0];
            ALU_SRL:  ALU_Out = A >> B[4:0];
            ALU_SRA:  ALU_Out = $signed(A) >>> B[4:0];
            
            // Comparisons
            ALU_SLT:  ALU_Out = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            ALU_SLTU: ALU_Out = (A < B) ? 32'd1 : 32'd0;
            
            // Default Case (Safety)
            default:  ALU_Out = 32'b0;
        endcase
    end

endmodule