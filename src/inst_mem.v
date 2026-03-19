

module inst_mem(
    input [31:0] addr,    
    output [31:0] data    
    );

    // 16KB Memory (4096 words)
    reg [31:0] mem [0:4095];
    integer i;

    initial begin
        //  Initialize everything to zero 
        
        for (i=0; i<4096; i=i+1) 
            mem[i] = 32'b0;
            
//--------------------------------------------------------------------------------//
        
        
        // Format: $readmemh("filelocation", array_name);
        $readmemh("/home/athxrvav/Documents/RISC V/RISCV/RISCV.srcs/sources_1/new/program.hex", mem);
    end

    assign data = mem[addr[31:2]];

endmodule