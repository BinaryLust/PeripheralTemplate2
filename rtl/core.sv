

// counter reg and bit map
`define reg_counter        0
`define bits_counter       31:0

// config reg and bit map
`define reg_config         1
`define bits_counter_en    0
`define bits_counter_dir   1
`define bits_counter_ire   2

// status reg and bit map
`define reg_status         2
`define bits_counter_lt_1k 0



// interface definition
interface core_io;

    parameter REGS = 3;


    // clocks and resets
    logic          clk;
    logic          reset;


    // device register lines
    logic  [31:0]  data_in;
    logic  [31:0]  data_out  [REGS-1:0];
    logic          write_en  [REGS-1:0];
    logic          read_en   [REGS-1:0];


    // interrupt request lines
    logic          irq_out;


    // modport list (used to define signal direction for specific situations)
    modport in (
        input   clk,
        input   reset,
        input   data_in,
        output  data_out,
        input   write_en,
        input   read_en,
        output  irq_out
    );


    // a function to return the number of registers in the interface
    // you can't just read the parameter for some reason...
    function integer regs();
        regs = REGS;
    endfunction


endinterface


// core code
module core(
    core_io.in  io
    );


    // device registers
    logic  [31:0]  counter;        // counter value
    logic          counter_en;     // counter enable
    logic          counter_dir;    // counter direction
    logic          counter_ire;    // counter interrupt request enable
    logic          counter_lt_1k;  // counter less than 1000


    // hidden registers
    logic          counter_irq;    // counter interrupt request


    // other internal logic signals
    logic  [31:0]  counter_next;
    logic          counter_en_next;
    logic          counter_dir_next;
    logic          counter_ire_next;
    logic          counter_lt_1k_next;
    logic          counter_irq_next;


    // register block
    always_ff @(posedge io.clk or posedge io.reset) begin
        if(io.reset) begin
            // reset conditions
            counter        <= 32'b0;
            counter_en     <= 1'b0;
            counter_dir    <= 1'b0;
            counter_ire    <= 1'b0;
            counter_lt_1k  <= 1'b0;
            counter_irq    <= 1'b0;
        end else begin
            // default conditions
            counter        <= counter_next;
            counter_en     <= counter_en_next;
            counter_dir    <= counter_dir_next;
            counter_ire    <= counter_ire_next;
            counter_lt_1k  <= counter_lt_1k_next;
            counter_irq    <= counter_irq_next;
        end
    end


    // combinational logic block
    always_comb begin
        // default logic values
        io.data_out         = '{io.regs(){32'b0}};   // set all output lines to zero
        counter_irq_next    = 1'b0;                  // do not signal an interrupt
        counter_next        = counter;               // retain old count value
        counter_en_next     = counter_en;            // retain old data
        counter_dir_next    = counter_dir;           // retain old data
        counter_ire_next    = counter_ire;           // retain old data
        counter_lt_1k_next  = counter_lt_1k;         // retain old data


        // counter logic
        if(io.write_en[`reg_counter])
            counter_next = io.data_in[`bits_counter]; // load new count from bus master
        else begin
            if(counter_en) begin                      // if counting is enabled then
                if(counter_dir)
                    counter_next = counter + 32'd1;   // count up
                else
                    counter_next = counter - 32'd1;   // count down
            end
        end


        // config logic
        if(io.write_en[`reg_config]) begin
            counter_en_next  = io.data_in[`bits_counter_en];  // load new config value from bus master
            counter_dir_next = io.data_in[`bits_counter_dir]; // load new config value from bus master
            counter_ire_next = io.data_in[`bits_counter_ire]; // load new config value from bus master
        end


        // status logic
        counter_lt_1k_next = counter < 1000;         // set the less than 1000 status flag if the count is less than 1000


        // interrupt triggering logic
        if(counter_ire && &counter[15:0])            // trigger an interrupt if interrupts are enabled and
            counter_irq_next = 1'b1;                 // the lower 16 bits of the counter are set


        // assign output values
        io.data_out[`reg_counter][`bits_counter]      = counter;
        io.data_out[`reg_config][`bits_counter_en]    = counter_en;
        io.data_out[`reg_config][`bits_counter_dir]   = counter_dir;
        io.data_out[`reg_config][`bits_counter_ire]   = counter_ire;
        io.data_out[`reg_status][`bits_counter_lt_1k] = counter_lt_1k;
        io.irq_out                                    = counter_irq;

    end


endmodule

