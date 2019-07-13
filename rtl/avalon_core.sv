

// register map
// address //   bits    //  registers       // type   //  access type  // value meaning
//       0      [31:0]      counter            data       read/write
//       1      [0]         count enable       config     read/write    (1 for enable, 0 for disable)
//       1      [1]         count direction    config     read/write    (1 for up,     0 for down)
//       1      [2]         count int enable   config     read/write    (1 for enable, 0 for disable)
//       2      [0]         count < 1000       status     read only     (1 for yes,    0 for no)


// interface definition
interface avalon_io;
    logic          clk;
    logic          reset;
    logic          read;
    logic          write;
    logic  [1:0]   address;
    logic  [31:0]  data_in;
    logic          read_valid;
    logic  [31:0]  data_out;
    logic          irq;


    modport in (
        input   clk,
        input   reset,
        input   read,
        input   write,
        input   address,
        input   data_in,
        output  read_valid,
        output  data_out,
        output  irq
    );

endinterface


module avalon_core(
    avalon_io.in io
    );


    // internal logic signals
    core_io         c_io();
    logic    [1:0]  address; // registered address from the previous cycle


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            address       <= 2'b0;
            io.read_valid <= 1'b0;
        end else begin
            address       <= io.address;
            io.read_valid <= io.read;
        end
    end


    // combinational logic block
    always_comb begin
        // default values
        c_io.write_en = '{c_io.regs(){1'b0}};
        c_io.read_en  = '{c_io.regs(){1'b0}};


        // generate device register read/write signals
        if(io.write) c_io.write_en[io.address] = 1'b1;
        if(io.read)  c_io.read_en[io.address]  = 1'b1;


        // assign io.data_out to device register at registered address
        io.data_out = c_io.data_out[address];


        // other assignments
        c_io.clk     = io.clk;
        c_io.reset   = io.reset;
        c_io.data_in = io.data_in;
        io.irq       = c_io.irq_out;
    end


    // instantiate the core
    core
    core(
        .io  (c_io)
    );


endmodule

