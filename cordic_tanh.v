// FPGA Assignment 4 - Part 1
// Author: Roozmehr Jalilian (97101467)

// CORDIC - tanh Function
module cordic_tanh
	#(	// Parameters
		parameter WI = 8,					// fixed-point integer BW
		WF = 16,							// fixed-point fractional BW
		N = 13,								// no. of main iterations
		M = 2,								// no. of negative iterations minus 1
		WC = 4								// iteration counter BW
	)
	(	// Ports Declaration
		input wire iClk,						// clock
		input wire iRst,						// async. reset
		input wire iStart,						// start signal
		input wire signed [WI-1:-WF] iX,		// x input
		input wire signed [WI-1:-WF] iY,		// y input
		input wire signed [WI-1:-WF] iZ,		// z input
		output reg signed [WI-1:-WF] oX,		// x output
		output reg signed [WI-1:-WF] oY,		// y output
		output reg signed [WI-1:-WF] oZ,		// z output
		output wire oDone						// finish signal
	);

//---------- Local Parameters ----------//
	localparam RT = 3'b000, HYPER_NEG = 3'b001, HYPER_MAIN = 3'b010,
			   DIV = 3'b011, DONE = 3'b100;
			   // RT = reset,
			   // HYPER_NEG & HYPER_MAIN = negative and main hyperbolic mode
			   // DIV = division mode
			   // DONE = finish
//--------------------------------------//

//---------- Wire & Variable Declaration ----------//
	// Datapath
	wire [WC-1:0] shamt;						// right-shift amount
	wire [WC-1:0] cIter2;						// iteration counter + 2
	wire di;									// sign control
												// 0 = positive, 1 = negative
	wire signed [WI-1:-WF] sX;					// shifted X
	wire signed [WI-1:-WF] sY;					// shifted Y
	wire signed [WI-1:-WF] mX;					// modified X
	wire signed [WI-1:-WF] mY;					// modified Y
	wire signed [WI-1:-WF] mZ;					// ROM output
	wire signed [WI-1:-WF] mX_neg;				// neg. modified X
	wire signed [WI-1:-WF] mY_neg;				// neg. modified Y
	wire signed [WI-1:-WF] mZ_neg;				// neg. ROM & 2^-i MUX output
	
	// Adder Inputs & Outputs
	wire signed [WI-1:-WF] adderX_in;
	wire signed [WI-1:-WF] adderY_in;
	wire signed [WI-1:-WF] adderZ_in;
	wire signed [WI-1:-WF] adderX_out;
	wire signed [WI-1:-WF] adderY_out;
	wire signed [WI-1:-WF] adderZ_out;
	
	reg cStall;									// stall flag (used for iteration repeat)
	reg [WC-1:0] cIter;							// current iteration counter
	reg [WC:0] cCounter;						// total iter. counter (used for ROM address)
	
	// Control Signals
	reg iterSel;								// negative & main iter. selector
												// 0 = negative, 1 = main
	reg nStall;									// next stall flag
	reg [WC-1:0] nIter;							// next iter. counter value
	reg [WC:0] nCounter;						// next total counter
	reg mode;									// operation mode
												// 0 = hyperbolic, 1 = division										
	
	// State Machine Variables											
	reg [2:0] cState, nState;					// current & next states
//-------------------------------------------------//

//---------- Continuous Assignments ----------//
	assign di = (~mode) ? oZ[WI-1] : oX[WI-1] ~^ oY[WI-1];
	// NOTE: di = sign(Z) or -sign(X*Y), depending on 'mode'
	assign cIter2 = cIter + 2'b10;
	assign shamt = (~iterSel) ? cIter2 : cIter;
	// NOTE: shift amount = i+2 for i<=0 and -i for i>0; i = no. of iteration
	assign sX = oX>>>shamt;
	assign sY = oY>>>shamt;
	assign mX = (~iterSel) ? oX - sX : sX;
	assign mY = (~iterSel) ? oY - sY : sY;
	assign mX_neg = ~mX + $signed({1'b0,1'b1});
	assign mY_neg = ~mY + $signed({1'b0,1'b1});
	assign mZ_neg = ~mZ + $signed({1'b0,1'b1});
	assign adderX_in = (~mode) ? ((~di) ? mY : mY_neg) : {(WI+WF){1'b0}};
	assign adderY_in = (~di) ? mX : mX_neg;
	assign adderZ_in = (~di) ? mZ_neg : mZ;
	assign adderX_out = oX + adderX_in;
	assign adderY_out = oY + adderY_in;
	assign adderZ_out = oZ + adderZ_in;
	assign oDone = (cState == DONE) ? 1'b1 : 1'b0;
//--------------------------------------------//

//---------- Module Instantiations ----------//
	cordic_ROM ROM0(.iAddr(cCounter), .oQ(mZ));		// ROM module
//-------------------------------------------//

//---------- Combinational Logic ----------//
	always @(cState, iStart, cIter, cCounter, cStall) begin
		mode = 0;
		nState = RT;
		nIter = cIter;
		nCounter = cCounter;
		nStall = 0;
		iterSel = 0;
		case(cState)
			RT: nState = (iStart) ? HYPER_NEG : RT;
			HYPER_NEG: begin
				nState = (cIter == {WC{1'b0}}) ? HYPER_MAIN : HYPER_NEG;
				// if iteration no. = 0 goto main hyperbolic state
				nIter = (cIter == {WC{1'b0}}) ? $unsigned(1) : cIter - 1'b1;
				// down counts iteration number until reaches 0
				nCounter = cCounter + 1'b1;
			end
			HYPER_MAIN: begin
				iterSel = 1;
				nState = (cIter == N && !cStall) ? DIV : HYPER_MAIN;
				// if iter. no. = N goto division state
				if (!cStall) begin
					nIter = (cIter == N) ? $unsigned(1) : cIter + 1'b1;
					// up counts iteration number until reaches N
					nCounter = cCounter + 1'b1;
					nStall = (cIter == 3 || cIter == 12) ? 1'b1 : 1'b0;
					// repeats iterations 4 and 13 (to ensure convergence)
				end	
			end
			DIV: begin
				mode = 1;
				iterSel = 1;
				nState = (cIter == N) ? DONE : DIV;
				// if iter. no. = N then we're done
				nIter = cIter + 1'b1;
				nCounter = cCounter + 1'b1;			
			end
			DONE: nState = DONE;	// remain in this state until next reset
		endcase
	end
//----------------------------------------//

//---------- Sequential Logic ----------//
	always @(posedge iClk or posedge iRst) begin
		if (iRst) begin				// reset
			cStall = 1'b0;
			cIter <= $unsigned(M);
			cCounter <= {(WC+1){1'b0}};
			cState <= RT;
			oX <= {(WI+WF){1'b0}};
			oY <= {(WI+WF){1'b0}};
			oZ <= {(WI+WF){1'b0}};
		end
		else begin
			if (!oDone) begin
				// Initial & Normal Register Behaviors
				oX <= (cState == RT && iStart) ? iX : adderX_out;
				oY <= (cState == RT && iStart) ? iY : adderY_out;
				if (cState == RT)
					oZ <= (iStart) ? iZ : {(WI+WF){1'b0}};
				else if (cState == HYPER_MAIN && cIter == N && !cStall)
					oZ <= {(WI+WF){1'b0}};
					// Z must be set to 0 at the start of division stage
				else
					oZ <= adderZ_out;
			end
			// Current Value <= Next Value
			cStall <= nStall;
			cIter <= nIter;
			cCounter <= nCounter;
			cState <= nState;
		end
	end
//--------------------------------------//

endmodule
