// Code your design here
module uart_top #(parameter freq=1000000, parameter baud=9600)(input clk,rst,newd,rx,input [7:0]tx_data, output done_tx,done_rx,tx, output [7:0] rx_data);
  
  uart_tx #(freq, baud) mod1 (clk,rst,newd,tx_data,tx,done_tx);
  uart_rx #(freq, baud) mod2 (clk,rst,rx,done_rx,rx_data);
  
endmodule
/////////////////////////////////////////
module uart_tx #(parameter freq=1000000, parameter baud=9600) (input clk,rst,newd,input [7:0] tx_data, output reg tx,done_tx);
  
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
            	state <= transfer;
            	done_tx <=0;
          	end
          
          	else begin
            	din <= 0;
            	state <= idle;
          	end
        end
          
         transfer : begin
            	if(count <= 7) begin
              		tx <= din[count];
              		count <= count+1;
              		state<= transfer;
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
//////////////////////////////////////////////////////////
        module uart_rx #(parameter freq=1000000, parameter baud=9600)(input clk,rst,input rx,output reg done_rx,output reg [7:0] rx_data);
          
          localparam clk_fre = freq/baud;
          int countc=0;
          int count=0;
          reg uclk =0;
          reg [7:0]temp;
          
          typedef enum bit[1:0] {idle = 2'b00 , receive = 2'b11} state_type;
          state_type state = idle;
          
          always @(posedge clk) begin
            if(countc <= clk_fre/2) begin
              countc <= countc+1;
            end
            else begin
              countc <=0;
              uclk <= ~uclk;
            end
          end
          
          always @(posedge uclk) begin
            
            if(rst) begin
              done_rx <= 0;
              rx_data <=8'd0;
              count <=0;
            end
            
            else begin
              
              case(state)
                
                idle : begin
                  	count <= 0;
                  	done_rx <= 0;
                  	rx_data <= 0;
                  
                  	if(rx==0) begin
                  		state <= receive;
                  	end
                  
                  	else begin
                    	state <= idle;
                  	end
                end
                
                receive : begin
                  //////////////////
                 	 if(count<=7) begin
                  	  	 rx_data <= {rx,rx_data[7:1]}; 
                   		 count<=count+1;
                 	 end 
                     else begin
                    	count<=0;
                    	done_rx <= 1;
                    	state <= idle;
                  	end
                end
                
                default : state <= idle;
                  
              endcase
              
            end
            
          end 
endmodule
////////////////////////////////////////////////
interface uart_in;
  
  logic clk,rst;
  logic newd;
  logic [7:0]tx_data;
  logic rx;
  logic [7:0]rx_data;
  logic tx;
  logic done_tx;
  logic done_rx;
  logic uclk_tx;
  logic uclk_rx;
  logic [7:0]tx_data_tx;
  
endinterface
