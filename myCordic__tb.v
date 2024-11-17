// FPGA Assignment 4 - Part 1 Testbench
// Author: Roozmehr Jalilian (97101467)
`timescale 1ns/1ns
`define PERIOD 10							// clock period

module myCordic__tb();
	
//---------- Local Parameters ----------//
		parameter WI = 4,					// input fixed-point integer BW
		WF = 16,							// input fixed-point fractional BW
		WIO = 8,							// output fixed-point integer BW
		WFO = 16;							// output fixed-point fractional BW
		parameter SIZE = 1801;				// test vector lenght
//--------------------------------------//

//---------- Wire & Variable Declaration ----------//
	reg Rst;										// async. reset
	reg Start;										// start signal
	reg [WIO-1:-WFO] sim_data;						// simulation output vector
	reg [WIO-1:-WFO] mat_data;						// MATLAB output vector
	reg signed [WI-1:-WF] In;						// input angle
	reg signed [WI-1:-WF] V [0:SIZE-1];				// input test vector array
	wire signed [WIO-1:-WFO] Out;					// output (tanh(In))
	wire isDone;									// finish flag
//-------------------------------------------------//

//---------- Clock Signal Generation ----------//
	reg Clk = 1'b1;
    always @(Clk)
        Clk <= #(`PERIOD/2) ~Clk;
//---------------------------------------------//

//---------- Integer Declaration ----------//
	integer k;
    integer fileID1;								// file 1 pointer
    integer fileID2;								// file 2 pointer
    integer scan_file1;								// scanf of file 1
    integer scan_file2;								// scanf of file 2
//-----------------------------------------//

//---------- Initial Block ----------//
    initial begin
        Rst = 1;
        In = 0;
        Start = 0;
		$readmemh("input_vector.txt", V);				// read from test vector file
		fileID1 = $fopen("output_VERILOG.txt", "w");	// prepare to write output data		
		
		@(posedge Clk);
		Rst = 0;
		@(posedge Clk);
		@(posedge Clk);
		
		for (k=0; k<SIZE; k=k+1) begin
			Start = 1;
			In = V[k];
			@(posedge Clk);
			Start = 0;
			In = {(WFO+WIO){1'bx}};
			wait (isDone);								// wait till finished
			$fwrite(fileID1, "%x\n", Out);
			@(posedge Clk);
			@(posedge Clk);
			Rst = 1;									// reset for new input
			@(posedge Clk);
			Rst = 0;
			@(posedge Clk);
		end
		$fclose(fileID1);
		
		// Compare MATLAB and Simulation Outputs
		fileID1 = $fopen("output_VERILOG.txt", "r");
		fileID2 = $fopen("output_MATLAB.txt","r");
		scan_file1 = $fscanf(fileID1, "%x\n", sim_data);
		scan_file2 = $fscanf(fileID2, "%x\n", mat_data);
		while (!$feof(fileID1) && !$feof(fileID1)) begin
			if (mat_data != sim_data) begin
				$display("ERROR: Mismatch detected!");
				$fclose(fileID1);
				$fclose(fileID2);
				$stop;
			end
			else begin
				scan_file1 = $fscanf(fileID1, "%x\n", sim_data);
				scan_file2 = $fscanf(fileID2, "%x\n", mat_data);
			end
		end
		$display("SUCCESS: Simulation matches MATLAB output!");
		$fclose(fileID1);
		$fclose(fileID2);
		$stop;
		
    end
//-----------------------------------//

//---------- Device Under Test ----------//
	myCordic C0(
		.Clk(Clk),
		.Rst(Rst),
		.Start(Start),
		.X(In),
		.tanhX(Out),
		.Done(isDone)
	);
//---------------------------------------//

endmodule
