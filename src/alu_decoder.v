

module alu_decoder(
    input [1:0] ALUOp,       // From Control Unit
    input [2:0] funct3,      // Instruction bits [14:12]
    input [6:0] funct7,      // Instruction bits [31:25] 
    input [6:0] opcode,      // Opcode
    output reg [3:0] ALUControl
    );

    // ALU Parameters (Same as in alu.v)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b1000;
    localparam ALU_AND  = 4'b0111;
    localparam ALU_OR   = 4'b0110;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0001;
    localparam ALU_SRL  = 4'b0101;
    localparam ALU_SRA  = 4'b1101;
    localparam ALU_SLT  = 4'b0010;
    localparam ALU_SLTU = 4'b0011;

    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = ALU_ADD; // LW, SW (Force Add)
            2'b01: ALUControl = ALU_SUB; // BEQ (Force Sub)
            
            2'b10: begin // R-Type or I-Type
                case(funct3)
                    3'b000: begin // ADD or SUB
                        // Bit 30 of the instruction is index 5 of funct7 ([6:5:4:3:2:1:0])
                        // If it is R-Type (0110011) AND Bit 30 is 1 -> SUB
                        if (opcode == 7'b0110011 && funct7[5] == 1'b1) 
                             ALUControl = ALU_SUB;
                        else 
                             ALUControl = ALU_ADD;
                    end
                    
                    3'b001: ALUControl = ALU_SLL;  // SLL
                    3'b010: ALUControl = ALU_SLT;  // SLT
                    3'b011: ALUControl = ALU_SLTU; // SLTU
                    3'b100: ALUControl = ALU_XOR;  // XOR
                    
                    3'b101: begin // SRL or SRA
                        // Check Bit 30 (funct7[5])
                        if (funct7[5] == 1'b1) ALUControl = ALU_SRA;
                        else ALUControl = ALU_SRL;
                    end
                    
                    3'b110: ALUControl = ALU_OR;   // OR
                    3'b111: ALUControl = ALU_AND;  // AND
                    default: ALUControl = ALU_ADD;
                endcase
            end
            
            default: ALUControl = ALU_ADD;
        endcase
    end
endmodule