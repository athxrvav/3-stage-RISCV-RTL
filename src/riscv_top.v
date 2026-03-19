`timescale 1ns / 1ps

module riscv_top (
    input clk,
    input reset,
    output wire [31:0] result // Debug Output
);

    // =====================================
    // --- WIRES & CONTROL SIGNALS ---
    // ======================================
    
    // --- Hazard Unit Signals ---
    wire       Stall_F, Stall_D, Flush_E;
    wire [1:0] ForwardAE, ForwardBE;
    
    // --- Fetch Stage (F) ---
    reg  [31:0] PC_F;
    wire [31:0] PC_Next_F;
    wire [31:0] PC_Plus4_F;
    wire [31:0] Instr_F;
    
    // --- Decode Stage (D) ---
    reg  [31:0] Instr_D, PC_D;
    wire [31:0] Imm_D, RD1_D, RD2_D;
    
    // Control Signals (Decode)
    wire       RegWrite_D, MemtoReg_D, MemWrite_D, ALUSrc_D, Branch_D, MemRead_D;
    wire [1:0] ALUOp_D;
    wire [4:0] Rs1_D = Instr_D[19:15];
    wire [4:0] Rs2_D = Instr_D[24:20];
    wire [4:0] Rd_D  = Instr_D[11:7];
    wire [6:0] opcode = Instr_D[6:0];

    // --- Execute Stage (E) ---
    // Registers (Pipeline State)
    reg  [31:0] RD1_E_Reg, RD2_E_Reg, Imm_E, PC_E;
    reg  [4:0]  Rd_E_Reg, Rs1_E_Reg, Rs2_E_Reg;
    reg  [31:0] Instr_E_Func;
    
    // Control Registers
    reg         RegWrite_E, MemtoReg_E, MemWrite_E, ALUSrc_E, Branch_E, MemRead_E;
    reg  [1:0]  ALUOp_E;

    // Execution Wires
    wire [31:0] SrcA_E, SrcB_E, WriteData_E; // Inputs to ALU
    wire [31:0] ALUResult_E;
    wire        Zero_E;
    wire [3:0]  ALUControl_E;
    wire [31:0] ReadData_E;
    wire [31:0] Result_E;      // Final Writeback Value
    
    // Branch Logic (Calculated in Execute)
    wire [31:0] PC_Branch_E = PC_E + Imm_E;
    wire        PCSrc_E     = Branch_E & Zero_E; // Branch Decision


    // ===============================================
    // --- HAZARD UNIT INSTANCE ---
    // ============================================
    hazard_unit h_unit (
        // Forwarding Logic Inputs
        .Rs1_E(Rs1_E_Reg),
        .Rs2_E(Rs2_E_Reg),
        .Rd_M(Rd_E_Reg),        // Result of instruction currently in Execute (M/W)
        .RegWrite_M(RegWrite_E),
        .Rd_W(Rd_E_Reg),        // Safety backup (structurally same point in 3-stage)
        .RegWrite_W(RegWrite_E),
        
        // Stall Logic Inputs
        .Rs1_D(Rs1_D),
        .Rs2_D(Rs2_D),
        .MemRead_E(MemRead_E), // Is current instruction a Load?
        .Rd_E_Load(Rd_E_Reg),  // Dest of the Load
        
        // Outputs
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .Stall_F(Stall_F),
        .Stall_D(Stall_D),
        .Flush_E(Flush_E)
    );


    // =========================================
    // --- STAGE 1: FETCH (F) ---
    // ======================================
    
    
    assign PC_Plus4_F = PC_F + 4;
    
    // PC Mux: 1. Branch (Highest Prio) 2. Stall (Keep same) 3. Next (Normal)
    assign PC_Next_F = (PCSrc_E) ? PC_Branch_E : 
                       (Stall_F) ? PC_F : 
                                   PC_Plus4_F;

    always @(posedge clk or posedge reset) begin
        if (reset) 
            PC_F <= 0;
        else 
            PC_F <= PC_Next_F;
    end

    inst_mem imem (
        .addr(PC_F), 
        .data(Instr_F)
    );


    // ===============================================
    // --- PIPELINE REGISTER 1: IF -> ID ---
    // =================================================
    
    
    always @(posedge clk or posedge reset) begin
    
        if (reset) begin
            Instr_D <= 0;
            PC_D    <= 0;
        end 
        else if (PCSrc_E) begin // Synchronous Flush (Branch Taken)
            Instr_D <= 0;
            PC_D    <= 0;
        end 
        else if (!Stall_D) begin // Only update if NOT Stalled
            Instr_D <= Instr_F;
            PC_D    <= PC_F;
        end
        // Implicit Else: If Stalled, hold current value!
    end


    // ===================================
    // --- STAGE 2: DECODE (D) ---
    // ===================================

    // Control Unit
    control_unit ctrl (
        .opcode(Instr_D[6:0]),
        .ALUOp(ALUOp_D),
        .Branch(Branch_D),
        .MemRead(MemRead_D),   
        .MemtoReg(MemtoReg_D),
        .MemWrite(MemWrite_D),
        .ALUSrc(ALUSrc_D),
        .RegWrite(RegWrite_D)
    );

    // Register File
    reg_file rf (
        .clk(clk),
        .we(RegWrite_E),       // Write Enable comes from Execute (Writeback)
        .ra1(Rs1_D),
        .ra2(Rs2_D),
        .wa(Rd_E_Reg),         // Write Address from Execute
        .wd(Result_E),         // Write Data from Execute
        .rd1(RD1_D),
        .rd2(RD2_D)
    );

    // Immediate Generation
    wire [31:0] imm_I = {{20{Instr_D[31]}}, Instr_D[31:20]};
    wire [31:0] imm_S = {{20{Instr_D[31]}}, Instr_D[31:25], Instr_D[11:7]};
    wire [31:0] imm_B = {{19{Instr_D[31]}}, Instr_D[31], Instr_D[7], Instr_D[30:25], Instr_D[11:8], 1'b0};

    assign Imm_D = (opcode == 7'b1100011) ? imm_B : 
                   (opcode == 7'b0100011) ? imm_S : 
                                            imm_I;


    // =================================================
    // --- PIPELINE REGISTER 2: ID -> EX ---
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset everything asynchronously
            RegWrite_E <= 0; MemtoReg_E <= 0; MemWrite_E <= 0;
            ALUSrc_E <= 0; Branch_E <= 0; ALUOp_E <= 0; MemRead_E <= 0;
            
            RD1_E_Reg <= 0; RD2_E_Reg <= 0; Imm_E <= 0;
            PC_E <= 0; Rd_E_Reg <= 0; Instr_E_Func <= 0;
            Rs1_E_Reg <= 0; Rs2_E_Reg <= 0;
        end 
        else if (PCSrc_E || Flush_E) begin 
            // Synchronous Flush (Branch or Stall Bubble)
            RegWrite_E <= 0; MemtoReg_E <= 0; MemWrite_E <= 0;
            ALUSrc_E <= 0; Branch_E <= 0; ALUOp_E <= 0; MemRead_E <= 0;
            
            RD1_E_Reg <= 0; RD2_E_Reg <= 0; Imm_E <= 0;
            PC_E <= 0; Rd_E_Reg <= 0; Instr_E_Func <= 0;
            Rs1_E_Reg <= 0; Rs2_E_Reg <= 0;
        end 
        else begin
            // Normal Operation
            RegWrite_E <= RegWrite_D; MemtoReg_E <= MemtoReg_D; MemWrite_E <= MemWrite_D;
            ALUSrc_E   <= ALUSrc_D;   Branch_E   <= Branch_D;   ALUOp_E    <= ALUOp_D;
            MemRead_E  <= MemRead_D;

            RD1_E_Reg    <= RD1_D;
            RD2_E_Reg    <= RD2_D;
            Imm_E        <= Imm_D;
            PC_E         <= PC_D;
            Rd_E_Reg     <= Rd_D;
            Instr_E_Func <= Instr_D;
            
            Rs1_E_Reg    <= Rs1_D;
            Rs2_E_Reg    <= Rs2_D;
        end
    end


    // ===============================
    // --- STAGE 3: EXECUTE (E) ---
    // =============================
    // --- FORWARDING MUXES ---
    // Selects: 00=RegFile, 01=Writeback(Forward), 10=ALUResult(Forward)
    assign SrcA_E = (ForwardAE == 2'b10) ? ALUResult_E : 
                    (ForwardAE == 2'b01) ? Result_E : 
                                           RD1_E_Reg;

    assign WriteData_E = (ForwardBE == 2'b10) ? ALUResult_E : 
                         (ForwardBE == 2'b01) ? Result_E : 
                                                RD2_E_Reg;

    // ALU Source B Mux
    assign SrcB_E = (ALUSrc_E) ? Imm_E : WriteData_E;

    // ALU Decoder
    alu_decoder alu_dec (
        .ALUOp(ALUOp_E),
        .funct3(Instr_E_Func[14:12]),
        .funct7(Instr_E_Func[31:25]),
        .opcode(Instr_E_Func[6:0]), 
        .ALUControl(ALUControl_E)
    );

    // ALU Instance
    alu my_alu (
        .ALU_Sel(ALUControl_E),
        .A(SrcA_E),
        .B(SrcB_E),
        .ALU_Out(ALUResult_E),
        .Zero(Zero_E)
    );

    // Data Memory
    data_mem dmem (
        .clk(clk),
        .we(MemWrite_E),
        .addr(ALUResult_E),
        .wd(WriteData_E), 
        .rd(ReadData_E)
    );

    // Writeback Mux
    assign Result_E = (MemtoReg_E) ? ReadData_E : ALUResult_E;

    // Final Output
    assign result = Result_E;

endmodule