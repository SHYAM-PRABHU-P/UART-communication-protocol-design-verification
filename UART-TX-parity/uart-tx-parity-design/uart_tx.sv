// Code your design here
// Code your design here

/////////////////////////////////////////
module uart_tx #(parameter freq=1000000, parameter baud=9600) (input clk,rst,newd,input [7:0] tx_data, output reg tx,parity,done_tx);
  
  localparam clk_count = freq/baud;
  int count=0;
  int countc=0;
  reg uclk = 0;
  reg [7:0]din;
  
  typedef enum bit[1:0] {idle = 2'b00 , transfer = 2'b11} state_type;
          state_type state = idle;
  
  always @(posedge clk) begin
    if(countc < clk_count/2)
      countc++;
    else begin
      uclk <= ~uclk;
      countc <= 0;
    end
  end
  
  always @(posedge uclk) begin
    
    if(rst) begin
      tx <= 1;
      din <= 8'd0;
      state <= idle;
      done_tx <=0;
    end
    
    else begin
      
      case(state)
        idle : begin
          	if(newd) begin
            	tx<=0;
            	din<=tx_data;
              	parity <= ~(^din);
            	state <= transfer;
            	done_tx <=0;
          	end
          
          	else begin
            	din <= 0;
            	state <= idle;
          	end
        end
          
         transfer : begin
           		if(count <= 8) begin
                  
                  if(count == 8) begin
                     tx <= parity;
                    count <= count+1;
                  end
                  else begin
              		tx <= din[count];
              		count <= count+1;
              		state<= transfer;
                  end
                  
            	end
           
            	else begin
              		count <=0;
              		state <= idle;
                    tx <=1;
              		done_tx <=1;
            	end
          end
     
        default : state <= idle;
        
      endcase
      
    end
    
  end
 
endmodule
///////////////////////////////////////////////////////////////
interface uart_in;
  
  logic clk,rst;
  logic newd;
  logic [7:0]tx_data;
  
  logic tx;
  logic done_tx;
  logic parity;
  logic uclk_tx;
  
  logic [8:0]tx_data_tx;
  
endinterface
