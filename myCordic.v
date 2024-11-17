// FPGA Assignment X - Part 1
// Author: Roozmehr Jalilian (97101467)

// Top-level CORDIC (tanh) Module
module myCordic
	#(	// Parameters
		parameter WI = 4,					// input fixed-point integer BW
		WF = 16,							// input fixed-point fractional BW
		WIO = 8,							// output fixed-point integer BW
		WFO = 16							// output fixed-point fractional BW
	)
	(	// Ports Declaration
		input wire Clk,						// clock
		input wire Rst,						// async. reset
		input wire Start,					// start signal
		input wire [WI-1:-WF] X,			// input angle
		output wire [WIO-1:-WFO] tanhX,		// output (tanh(X))
		output wire Done					// finish signal
	);

//---------- Wire & Variable Declaration ----------//
	// Primary Inputs
	wire [WIO-1:-WFO] X0;
	wire [WIO-1:-WFO] Y0;
	wire [WIO-1:-WFO] Z0;
//-------------------------------------------------//

//---------- Continuous Assignments ----------//
	assign X0 = 24'h0ad0ab;	// = 10.8151
	assign Y0 = {(WIO+WFO){1'b0}};
	assign Z0 = {{(WIO-WI){X[WI-1]}},X,{(WFO-WF){1'b0}}};	// bit extension
//--------------------------------------------//

//---------- Module Instantiations ----------//
	cordic_tanh CT0 (
		.iClk(Clk),
		.iRst(Rst),
		.iStart(Start),
		.iX(X0),
		.iY(Y0),
		.iZ(Z0),
		.oDone(Done),
		.oX(),
		.oY(),
		.oZ(tanhX)
	);
	defparam CT0.WI = WIO;
	defparam CT0.WF = WFO;
//-------------------------------------------//

endmodule
