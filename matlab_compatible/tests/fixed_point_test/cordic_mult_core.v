//**********************************************Cordic multiplier***********************************************************
//This example for vmodel MATLAB Verilog simulator
//
//Входы:
//  rst				 - Asynchronous reset
//  clk				 - Clock
//	start			 - Start strobe
//  a                - Multiplier signed (0 bits of integer part, N-1 bits of fractional part)
//  b                - Multiplier signed (0 bits of integer part, N-1 bits of fractional part)
//
//Выходы:
//	c				 - Product signed (0 bits of integer part, N-1 bits of fractional part)
//	rdy				 - Ready flag
//
//Параметры:
//	N				 - Inputs/outputs width
//
//Needs N+1 clock periods to perform calculations
//
//Author: Romanov A.M
//		  Control Problems Department MIREA, 2010
//Distributed under the GNU LGPL
//*************************************************************************************************************************

module cordic_mult_core
    #(parameter N=16)           //Inputs/outputs width
    (input clk,                 //Clock
     input rst,                 //Asynchronous reset
     input [N-1:0]a,            //Multiplier signed (0 bits of integer part, N-1 bits of fractional part)
     input [N-1:0]b,            //Multiplier signed (0 bits of integer part, N-1 bits of fractional part)
     input start,               //Start strobe
     output reg [N-1:0]c,       //Product signed (0 bits of integer part, N-1 bits of fractional part)
     output reg rdy);           //Ready flag
    
reg [N:0]x/*verilator public*/;         //Cordic variable x 
reg [N-1:0]y;       //Cordic variable y
reg [N-1:0]z;       //Cordic result
    
reg [N-1:0]subs;    //x correction buffer (stores value for x correction on the next step)
reg finish;         //Ready flag
    
always @(posedge clk, posedge rst)
    if(rst)
        begin
          x<=0;
          y<=0;
          z<=0; 
          subs[N-1]<=0;
          subs[N-2:0]<=0;
          c<=0;
          rdy <=0;
          finish <=0;
        end else
            begin
                if(start)
                    begin
                      x<={a[N-1],a};        //Parameter initialization on start
                      y<=b;                 
                      z<=0;                 
                      subs[N-1]<=1;        //setting subs into integer 1
                      subs[N-2:0]<=0;
                      finish <= 0;
                    end else
                    if(x[N])                        //if x<0
                    begin
                        x <= x + {1'b0,subs};       //x=x+2^-i
                        y <= {y[N-1],y[N-1:1]};     //y=y/2
                        z <= z - y;                 //z=z-y
                        {subs,finish} <= {1'b0,subs[N-1:0]};   //subs=subs/2
                    end else
                    begin                           //if x>=0
                        x <= x - {1'b0,subs};       //x=x-2^i
                        y <= {y[N-1],y[N-1:1]};     //y=y/2
                        z <= z + y;                 //z=z+y
                        {subs,finish} <= {1'b0,subs[N-1:0]};   //subs=subs/2
                    end
                    if(finish)                      //If subs=0 then multiplication is finished
                        begin                      
                           rdy<=1;                  //Setting ready flag
                           c <= z;                  //Saving result in c output
                           finish <= 0;
                        end else
                            rdy<=0;   
            end
endmodule
