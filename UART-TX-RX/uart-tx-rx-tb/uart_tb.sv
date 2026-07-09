// Code your testbench here
// or browse Examples
class transaction;
  
  typedef enum bit {write = 1'b0, read = 1'b1} state_type;
  rand state_type state;
  randc bit [7:0]tx_data;
  bit [7:0] tx_data_tx;
  bit rx;
  bit [7:0]rx_data;
  bit tx;
  
  function transaction copy();
    copy = new();
    copy.state = this.state;
    copy.tx_data=this.tx_data;
    copy.rx=this.rx;
    copy.tx_data_tx = this.tx_data_tx;
    copy.rx_data=this.rx_data;
    copy.tx=this.tx;
    
  endfunction
  
endclass
////////////////////////////////////////////
class generator;
  transaction tg;
  mailbox #(transaction) mbx_gd;
  event done;
  event sc_next;
  
  function new(mailbox #(transaction) mbx_gd);
    this.mbx_gd = mbx_gd;
    tg = new();
  endfunction
  
  task run;
  	for(int i=0;i<7;i++) begin
      $display("---------------------------------");
    	assert(tg.randomize()) else $display("Randomization Fails");
    	mbx_gd.put(tg.copy);
    	@(sc_next);
  	end
  	->done;
  endtask
  
endclass
///////////////////////////////////////////
class driver;
  transaction td;
  mailbox #(transaction) mbx_gd;
  mailbox #(bit [7:0]) mbx_ds;
  virtual uart_in ui;
  bit [7:0] din;
  bit [7:0] data_rx;
  
  function new(mailbox #(transaction) mbx_gd, mailbox #(bit[7:0])mbx_ds);
    this.mbx_gd= mbx_gd;
    this.mbx_ds = mbx_ds;
  endfunction

  task reset();
    ui.rst <= 1;
    ui.newd <= 0;
    ui.tx_data <= 0;
    ui.tx_data_tx <=0; //// important
    ui.rx <= 1;
    @(posedge ui.clk);
    repeat(3); @(posedge ui.clk);
    ui.rst <= 0;
  endtask
    
  task run();
    forever begin
      mbx_gd.get(td);
      if(td.state == 1'b0) begin						//////// write
      @(posedge ui.uclk_tx);
      ui.rst <= 0;
      ui.newd <= 1;
      ui.rx <= 1;
      ui.tx_data <= td.tx_data;
      @(posedge ui.uclk_tx);
      ui.newd <= 0;
        din =td.tx_data;
        mbx_ds.put(din);
    end
      
      else if(td.state == 1'b1) begin					//////// read
      @(posedge ui.uclk_rx);
      ui.rst <= 0;
      ui.newd <=0;
      ui.rx <=0;
      @(posedge ui.uclk_rx);
        for(int i=0;i<=7;i++) begin
          @(posedge ui.uclk_rx);
        ui.rx <= $urandom;
        data_rx[i]=ui.rx;
      end
      
        mbx_ds.put(data_rx);
      
  	  end
     end
  endtask
  
endclass
               
//////////////////////////////////////////////////////////
class monitor; 
  transaction tm;
  mailbox #(bit[7:0]) mbx_ms;
  virtual uart_in ui;
  bit [7:0] dout_tx;
  bit [7:0] dout_rx;
  
  
  function new(mailbox #(bit[7:0]) mbx_ms);
    this.mbx_ms = mbx_ms;
    
  endfunction
  
  task run;
    forever begin
      tm=new();
      @(posedge ui.uclk_tx);
      
      if((ui.rx == 1) && (ui.newd == 1)) begin
        @(posedge ui.uclk_tx);
        for(int i=0;i<=7;i++) begin
          @(posedge ui.uclk_tx);
          dout_tx[i] = ui.tx;
          //ui.tx_data_tx[i] = ui.tx;
        end
        wait(ui.done_tx == 1);//
        @(posedge ui.uclk_tx);
        ui.tx_data_tx = dout_tx;//
        mbx_ms.put(dout_tx);
      end
      
      else if(ui.rx == 0 && ui.newd == 0) begin
        @(posedge ui.uclk_rx); //
        wait(ui.done_rx == 1);
        dout_rx = ui.rx_data;
        @(posedge ui.uclk_rx);
        mbx_ms.put(dout_rx);
      end
      
    end
  endtask
  
endclass
////////////////////////////////////////////////////////

class scoreboard;
  mailbox #(bit [7:0]) mbx_ds;
  mailbox #(bit [7:0]) mbx_ms;
  bit [7:0] data_input;
  bit [7:0] data_output;
  event sc_next;
  
  function new(mailbox #(bit [7:0]) mbx_ds, mailbox #(bit [7:0]) mbx_ms);
  	this.mbx_ds = mbx_ds;
  	this.mbx_ms = mbx_ms;
  endfunction
  
  task run;
    forever begin
      mbx_ds.get(data_input);
      mbx_ms.get(data_output);
      if(data_input == data_output) begin
        $display("Successful");
      end
      else begin
        $display("Unsuccessful");
      end
      $display("----------------------------------------");
      ->sc_next;
    end
  endtask
  
endclass
////////////////////////////////////////////////////////
            
class environment;
  transaction t;
  generator g;
  driver d;
  monitor m;
  scoreboard s;
  
  virtual uart_in ui;
  
  event done;
  event sc_next;
  
  mailbox #(transaction) mbx_gd;
  mailbox #(bit[7:0]) mbx_ds;
  mailbox #(bit[7:0]) mbx_ms;
  
  function new(virtual uart_in ui);
    mbx_gd = new();
    mbx_ds = new();
    mbx_ms = new();
    
    g=new(mbx_gd);
    d=new(mbx_gd,mbx_ds);
    m=new(mbx_ms);
    s=new(mbx_ds,mbx_ms);
    
    g.sc_next = sc_next;
    g.done = done;
    s.sc_next = sc_next;
    
    this.ui = ui;
    d.ui = ui;
    m.ui = ui;
 
  endfunction
                
  task preset;
    d.reset();
  endtask
                
  task set;
    fork
      g.run;
      d.run;
      m.run;
      s.run;
    join_any
  endtask
                
  task postset;
    wait(g.done.triggered);
    $finish();
  endtask
                
  task run();
    preset;
    set;
    postset;
  endtask
  
endclass
////////////////////////////////////////////////////////
                
module uart_tb;
  environment e;
  uart_in ui();
  
  uart_top #(1000000,9600) dut (ui.clk,ui.rst,ui.newd,ui.rx,ui.tx_data,ui.done_tx,ui.done_rx,ui.tx,ui.rx_data);
  
  assign ui.uclk_tx = dut.mod1.uclk;
  assign ui.uclk_rx = dut.mod2.uclk;
  
  
  initial begin
    ui.clk <= 0;
  end
  
  always #10 ui.clk <= ~ui.clk;
  
  initial begin
    e=new(ui);
    e.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
  
endmodule
