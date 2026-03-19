module control_unit (
    input [6:0] opcode,
    output reg [1:0] ALUOp,
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite
);

    always @(*) begin
        // 1. DEFAULT VALUES (Prevents Latches)
        ALUOp = 2'b00;
        Branch = 0;
        MemRead = 0;
        MemtoReg = 0;
        MemWrite = 0;
        ALUSrc = 0;
        RegWrite = 0;

        // 2. OVERRIDE based on Opcode
        case(opcode)
            // R-Type Math (ADD, SUB, AND, OR, SLL, etc.)
            7'b0110011: begin
                ALUOp = 2'b10;   // Let alu_decoder decide
                RegWrite = 1;
            end

            // I-Type Math (ADDI, ANDI, SLLI, SRLI, etc.)
            7'b0010011: begin
                ALUOp = 2'b10;   // Let alu_decoder decide! (FIXED)
                ALUSrc = 1;      // Use Immediate
                RegWrite = 1;
            end

            // Load Word (LW)
            7'b0000011: begin
                ALUOp = 2'b00;   // Force ADD for memory address
                ALUSrc = 1;
                MemRead = 1;
                MemtoReg = 1;  
                RegWrite = 1;
            end

            // Store Word (SW)
            7'b0100011: begin
                ALUOp = 2'b00;   // Force ADD for memory address
                ALUSrc = 1;
                MemWrite = 1;
            end

            // Branch (BEQ)
            7'b1100011: begin
                ALUOp = 2'b01;   // Force SUB for comparison
                Branch = 1;
            end
        endcase
    end
endmodule
