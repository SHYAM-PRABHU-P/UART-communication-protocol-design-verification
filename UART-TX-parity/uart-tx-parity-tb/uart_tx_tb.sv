// Code your testbench here
// or browse Examples
class transaction;
  
  
  randc bit [7:0]tx_data;
  bit [8:0] tx_data_tx;
  bit rx;
  bit parity;
  
  bit tx;
  
  function transaction copy();
    copy = new();
 	copy.parity = this.parity;
    copy.tx_data=this.tx_data;
    
    copy.tx_data_tx = this.tx_data_tx;
    
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
  mailbox #(bit) mbx_parity_ds;
  virtual uart_in ui;
  bit [7:0] din;
  bit din_parity;
  
  function new(mailbox #(transaction) mbx_gd, mailbox #(bit[7:0])mbx_ds, mailbox #(bit) mbx_parity_ds);
    this.mbx_gd= mbx_gd;
    this.mbx_ds = mbx_ds;
    this.mbx_parity_ds = mbx_parity_ds;
  endfunction

  task reset();
    ui.rst <= 1;
    ui.newd <= 0;
    ui.tx_data <= 0;
    ui.tx_data_tx <=0;
    
    @(posedge ui.clk);
    repeat(3); @(posedge ui.clk);
    ui.rst <= 0;
  endtask
    
  task run();
    forever begin
      	mbx_gd.get(td);
					
      	@(posedge ui.uclk_tx);
      	ui.rst <= 0;
      	ui.newd <= 1;
      
      	ui.tx_data <= td.tx_data;
      
      	@(posedge ui.uclk_tx);
      	ui.newd <= 0;
        din =td.tx_data;
        mbx_ds.put(din);
        mbx_parity_ds.put(~(^din_parity));
      
     end
  endtask
  
endclass
               
//////////////////////////////////////////////////////////
class monitor; 
  transaction tm;
  mailbox #(bit[7:0]) mbx_ms;
  mailbox #(bit) mbx_parity_ms;
  virtual uart_in ui;
  bit [8:0] dout_tx;
  bit parity_tx;
  
  
  function new(mailbox #(bit[7:0]) mbx_ms,mailbox #(bit) mbx_parity_ms);
    this.mbx_ms = mbx_ms;
    this.mbx_parity_ms = mbx_parity_ms;
    
  endfunction
  
  task run;
    forever begin
      tm=new();
      @(posedge ui.uclk_tx);
      
      if(ui.newd == 1) begin
        @(posedge ui.uclk_tx);
        for(int i=0;i<=8;i++) begin
          @(posedge ui.uclk_tx);
          if(i<8)
            dout_tx[i] = ui.tx;
          else
            tm.parity = ui.tx;
          
          
        end
        wait(ui.done_tx == 1);
        @(posedge ui.uclk_tx);
           
        parity_tx = tm.parity;
        ui.tx_data_tx = {parity_tx,dout_tx};
        
        mbx_ms.put(dout_tx);
        mbx_parity_ms.put(parity_tx);
        
      end
      
      
      
    end
  endtask
  
endclass
/////////////////////////////////////////////

class scoreboard;
  mailbox #(bit [7:0]) mbx_ds;
  mailbox #(bit [7:0]) mbx_ms;
  mailbox #(bit) mbx_parity_ms;
  mailbox #(bit) mbx_parity_ds;
  bit [7:0] data_input;
  bit [7:0] data_output;
  bit parity_tx;
  bit din_parity;
  event sc_next;
  
  function new(mailbox #(bit [7:0]) mbx_ds, mailbox #(bit [7:0]) mbx_ms,mailbox #(bit) mbx_parity_ms,mailbox #(bit) mbx_parity_ds);
  	this.mbx_ds = mbx_ds;
  	this.mbx_ms = mbx_ms;
    this.mbx_parity_ms = mbx_parity_ms;
    this.mbx_parity_ds = mbx_parity_ds;
  endfunction
  
  task run;
    forever begin
      mbx_ds.get(data_input);
      mbx_parity_ds.get(din_parity);
      mbx_ms.get(data_output);
      mbx_parity_ms.get(parity_tx);
     
      if(data_input == data_output && din_parity == parity_tx) begin
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
  mailbox #(bit) mbx_parity_ms;
  mailbox #(bit) mbx_parity_ds;
  
  function new(virtual uart_in ui);
    mbx_gd = new();
    mbx_ds = new();
    mbx_ms = new();
    mbx_parity_ms = new();
    mbx_parity_ds = new();
    
    g=new(mbx_gd);
    d=new(mbx_gd,mbx_ds,mbx_parity_ds);
    m=new(mbx_ms,mbx_parity_ms);
    s=new(mbx_ds,mbx_ms,mbx_parity_ms,mbx_parity_ds);
    
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
                
module uart_tx_tb;
  environment e;
  uart_in ui();
  
  uart_tx #(1000000,9600) dut (ui.clk,ui.rst,ui.newd,ui.tx_data,ui.tx,ui.parity,ui.done_tx);
  
  assign ui.uclk_tx = dut.uclk;
  
  
  
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
