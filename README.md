# AMBA

## APB
### APB2接口
``` 
PCLK 			-Peripheral clock
PADDR[..]		-Peripheral address bus
PWRITE			-Peripheral read/write signal
PWDATA[..]		-Peripheral write data bus
PRDATA[..]		-Peripheral read data bus
PSELx			-Individual slave select signals
PENABLE			-Peripheral data enable
```
![](https://i.imgur.com/Z5KSbx0.png)
#
#### 读时序
![](https://i.imgur.com/ILOMLRV.png)
- PWRITE为0时表示读数据
- T0时刻PSEL为0，没有APB Bus上的操作
- T1时刻PSEL为1，PENABLE为0，此时为setup阶段，APB Bus上传输要读的地址
- T2时刻PSEL为1，PENABLE为1，此时为access阶段，APB Bus上传输读出的数据Data1，在这个时刻数据返回。

#### 写时序
![](https://i.imgur.com/dQxufsd.png)
- PWRITE为1时表示写数据
- T0时刻PSEL为0，没有APB Bus上的操作
- T1时刻PSEL为1，PENABLE为0，此时为setup阶段，APB Bus上传输要写的地址
- T2时刻PSEL为1，PENABLE为1，此时为access阶段，APB Bus上传写入的数据Data1

由于APB只要操作register，所以APB操作只有两拍足够。 APB3和APB4两拍是不够的

### APB3接口
``` 
PCLK 			-Peripheral clock
PADDR[..]		-Peripheral address bus
PWRITE			-Peripheral read/write signal
PWDATA[..]		-Peripheral write data bus
PRDATA[..]		-Peripheral read data bus
PSELx			-Individual slave select signals
PENABLE			-Peripheral data enable
PREADY			-Peripheral cannot respnd immediately
PSLVERR			-Peripheral error
```
APB3比APB2多了PREADY和PSLVERR信号，这两个都是output信号。 由于PREADY的信号的存在，APB3多了一个wait state的状态，所以APB3可能在两拍里面就完成不了数据传输，以有wait state的写时序为例
![](https://i.imgur.com/DxLVFcD.png)
- 在setup阶段后面PREADY拉低了，这个时候表示IP还没准备好，数据不会写入
- 再过了一拍之后,PREADY拉高，IP准备好了，这个时候APB3 Bus上的数据会写入到相应寄存器。

#### 什么情况下产生Error response？(PSLVERR)
APB的外设可以选择产生或者不产生error response，如果不产生的话，只需要把连接APB外设的模块（比如APB bridge）对应PSLVERR端口接0即可

在以下情况下，APB的模块需要产生error response：

1. 在访问APB外设的寄存器的时候，APB外设在功能设计的时候，认为此时应该产生error，具体情况要取决于外设的设计
2. 对于APB4的外设，如果能支持secure的话，当外设的secure寄存器被non-secure的transfer访问的时候，这时候需要产生error
3. 如果APB对unused（没有分配地址空间）的地址空间访问时候，这时候需要产生error。


### APB4接口
``` 
PCLK 			-Peripheral clock
PADDR[..]		-Peripheral address bus
PWRITE			-Peripheral read/write signal
PWDATA[..]		-Peripheral write data bus
PRDATA[..]		-Peripheral read data bus
PSELx			-Individual slave select signals
PENABLE			-Peripheral data enable
PREADY			-Peripheral cannot respnd immediately
PSLVERR			-Peripheral error
PPROT[..]		-Some attributes signals
PSTRB[..]		-Indicate which byte lanes to update in memory
```

|Bit|0|1|
|-|-|-|
|PPROT[0]|Normal Access|Privileged Access|
|PPROT[1]|Secure Access|Non-Secure Access|
|PPROT[2]|Data|Instruction|

![](https://i.imgur.com/XFam1W6.png)


## APB Demo
![](https://i.imgur.com/iiHqtMY.png)

下面是一个APB4 Slave的Demo，简化起见，不支持PPROT信号，PREADY常为1，不支持wait state，PSLVERR常为0，不返回错误。<br/>
从上图可以看到整个IP包含两个module，一个是apb4 interface，另一个是IP的register。下图是IP内部register的定义，这个IP很简单，没有control register和status register，只有data register。

![](https://i.imgur.com/oG3BKit.png)

### 代码实现

#### 顶层模块 cmsdk_apb4_eg_slave
```verilog
module cmsdk_apb4_eg_slave # (
	paramter ADDRWIDTH = 12 )
(
	input wire					PCLK,
	input wire 					PRESETn,
	
	input wire					PSEL,
	input wire[ADDRWIDTH-1:0]	PADDR,
	input wire					PENABLE,
	input wire					PWRITE,
	input wire[31:0]			PWDATA,
	input wire[3:0]				PSTRB,
	
	input wire[3:0]				ECOREVNUM
	
	output wire[31:0]			PRDATA,
	output wire					PREADY,
	output wire					PSLVERR);
	
	wire[ADDRWIDTH-1:0] 	reg_addr;
	wire					reg_read_en;
	wire 					reg_write_en;
	wire[3:0]				reg_byte_strobe;
	wire[31:0]				reg_wdata;
	wire[31:0]				reg_rdata;
	
	cmsdk_apb4_eg_slave_interface 
		#(.ADDRWIDTH (ADDRWIDTH))
		u_apb_eg_slave_interface (
		
		// APB4 interface
		.pclk			(PCLK),
		.presetn		(PRESETn),
		.psel			(PSEL),
		.paddr			(PADDR),
		.penable		(PENABLE),
		.pwrite			(PWRITE),
		.pstrb			(PSTRB),
		
		.prdata			(PRDATA),
		.pready			(PREADY),
		.pslverr		(PSLVERR),
		
		// Register interface
		.addr			(reg_addr),
		.read_en		(reg_read_en),
		.write_en		(reg_write_en),
		.byte_strobe	(reg_byte_strobe),
		.wdata			(reg_wdata),
		.rdata			(reg_data)
	);
	
	cmsdk_apb4_eg_slave_reg
		#(.ADDRWIDTH(ADDRWIDTH))
		u_apb_eg_slave_reg (
		.pclk			(PCLK),
		.presetn		(PRESETn),
		
		.addr			(reg_addr),
		.read_en		(reg_read_en),
		.write_en		(reg_write_en),
		.byte_strobe	(reg_byte_strobe),
		.wdata			(reg_wdata),
		.ecorevnum		(ECOREVNUM),
		.rdata			(reg_rdata)
	);
	
endmodule
```

#### cmsdk_apb4_eg_slave_interface

``` verilog
module cmsdk_apb4_eg_slave_interface #(
		parameter ADDRWIDTH = 12)
(
	input wire						pclk,
	input wire						presetn,
	
	//apb interface inputs
	input wire 						psel,
	input wire[ADDRWIDTH-1:0]		paddr,
	input wire						penable,
	input wire						pwrite,
	input wire[31:0]				pwdata,
	input wire[3:0]					pstrb,
	
	//apb interface outputs
	output wire[31:0]				prdata,
	output wire						pready,
	output wire						pslverr,
	
	//register interface
	output wire[ADDRWIDTH-1:0]		addr,
	output wire 					read_en,
	output wire						write_en,
	output wire[3:0]				byte_strobe,
	output wire[31:0]				wdata,
	input wire[31:0]				rdata
);

//APB interface
assign pready = 1'b1; 		//Always readay. Can be customized to support waitstate if required.
assign pslverr = 1'b0;		//Always OKAY. Can be customized to support error response if required.

// register read and write signal
assign addr = paddr;
assign read_en = psel & (~pwrite);	//assert for whole apb read transfer;
assign write_en = psel & (~penable) & pwrite;	//assert for the 1st cycle of write transfer.
assign byte_strobe = pstrb;
assign wdata = pwdata;
assign prdata = rdata;
	
endmodule
```

#### cmsdk_apb4_eg_slave_reg
```verilog
module cmsdk_apb4_eg_slave_reg #(
	parameter ADDRWIDTH = 12)
	(
	input wire					pclk,
	input wire					presetn,
	
	input wire[ADDRWIDTH-1:0]	addr,
	input wire					read_en,
	input wire					write_en,
	input wire[3:0]				byte_strobe,
	input wire[31:0]			wdata,
	input wire[3:0]				ecorevnum,
	output reg[31:0]			rdata);
	
localparam ARM_CMSDK_APB4_EG_SLAVE_PID4 = 32'h00000004;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID5 = 32'h00000000;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID6 = 32'h00000000;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID7 = 32'h00000000;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID0 = 32'h00000019;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID1 = 32'h000000B8;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID2 = 32'h0000001B;
localparam ARM_CMSDK_APB4_EG_SLAVE_PID3 = 32'h00000000;
localparam ARM_CMSDK_APB4_EG_SLAVE_CID0 = 32'h00000000;
localparam ARM_CMSDK_APB4_EG_SLAVE_CID1 = 32'h000000F0;
localparam ARM_CMSDK_APB4_EG_SLAVE_CID2 = 32'h00000005;
localparam ARM_CMSDK_APB4_EG_SLAVE_CID3 = 32'h000000B1;
	
	reg[31:0]				data0;
	reg[31:0]				data1;
	reg[31:0]				data2;
	reg[31:0]				data3;
	wire[3:0]				wr_sel;
	
	//module logic start
	//address decoding for write operations
	assign wr_sel[0] = ((addr[(ADDRWIDTH-1):2]==10'b00000000)&(write_en)) ? 1'b1 : 1'b0;
	assign wr_sel[1] = ((addr[(ADDRWIDTH-1):2]==10'b00000001)&(write_en)) ? 1'b1 : 1'b0;
	assign wr_sel[2] = ((addr[(ADDRWIDTH-1):2]==10'b00000010)&(write_en)) ? 1'b1 : 1'b0;
	assign wr_sel[3] = ((addr[(ADDRWIDTH-1):2]==10'b00000011)&(write_en)) ? 1'b1 : 1'b0;
	
	//register write, byte enable
	always @ (posedge pclk or negedge presetn) begin
		if (~presetn) begin
			data1 <= {32{1'b0}};
		end else if (wr_sel[0]) begin 
			if (byte_strobe[0])
				data0[7:0] <= wdata[7:0]
			if (byte_strobe[1])
				data0[15:8] <= wdata[15:8]
			if (byte_strobe[2])
				data0[23:16] <= wdata[23:16]
			if (byte_strobe[3])
				data0[31:24] <= wdata[31:24]
		end
	end
	
	always @ (posedge pclk or negedge presetn) begin
		if (~presetn) begin
			data1 <= {32{1'b0}};
		end else if (wr_sel[1]) begin 
			if (byte_strobe[0])
				data1[7:0] <= wdata[7:0]
			if (byte_strobe[1])
				data1[15:8] <= wdata[15:8]
			if (byte_strobe[2])
				data1[23:16] <= wdata[23:16]
			if (byte_strobe[3])
				data1[31:24] <= wdata[31:24]
		end
	end

	always @ (posedge pclk or negedge presetn) begin
		if (~presetn) begin
			data1 <= {32{1'b0}};
		end else if (wr_sel[2]) begin 
			if (byte_strobe[0])
				data2[7:0] <= wdata[7:0]
			if (byte_strobe[1])
				data2[15:8] <= wdata[15:8]
			if (byte_strobe[2])
				data2[23:16] <= wdata[23:16]
			if (byte_strobe[3])
				data2[31:24] <= wdata[31:24]
		end
	end	
	
	always @ (posedge pclk or negedge presetn) begin
		if (~presetn) begin
			data1 <= {32{1'b0}};
		end else if (wr_sel[3]) begin 
			if (byte_strobe[0])
				data3[7:0] <= wdata[7:0]
			if (byte_strobe[1])
				data3[15:8] <= wdata[15:8]
			if (byte_strobe[2])
				data3[23:16] <= wdata[23:16]
			if (byte_strobe[3])
				data3[31:24] <= wdata[31:24]
		end
	end
	
	
	always @ (read_en or addr or data0 or data1 or data2 or data3 or ecorevnum) begin
		case (read_en)
		1'b1: begin
			if (addr[11:4] == 8'h00) begin
				case(addr[3:2])
				2'b00: rdata = data0;
				2'b01: rdata = data1;
				2'b10: rdata = data2;
				2'b11: rdata = data3;
				default: rdata = {32{1'bx}};
				endcase
			end else if (addr[11:6] == 6'h3F) begin
				case(addr[5:2])
				4'b0100: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID4;
				4'b0101: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID5;
				4'b0110: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID6;
				4'b0111: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID7;
				4'b1000: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID0;
				4'b1001: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID1;
				4'b1010: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID2;
				4'b1011: rdata = ARM_CMSDK_APB4_EG_SLAVE_PID3;
				
				4'b1100: rdata = ARM_CMSDK_APB4_EG_SLAVE_CID0;
				4'b1101: rdata = ARM_CMSDK_APB4_EG_SLAVE_CID1;
				4'b1110: rdata = ARM_CMSDK_APB4_EG_SLAVE_CID2;
				4'b1111: rdata = ARM_CMSDK_APB4_EG_SLAVE_CID3;
				
				4'b0000, 4'b0001, 4'b0010, 4'b0011: rdata = {32'h00000000};
				default: rdata = {32{1'bx}};
				endcase
			end else begin 
				rdata = {32'h00000000};
			end
		end
		1'b0: begin
			rdata = {32{1'b0}};
		end
		default: begin
			rdata = {32{1'bx}};
		end
		endcase
	end
	
endmodule
```

#### 仿真波形
测试脚本很简单，就是往data1寄存器写入0x12345678，然后读出进行比较
```
I
L 50
W 0x10000004 0x12345678 w incr p0000 nolock okay
I
L 10
P 0x10000004 0x12345678 t3
q
```

![](https://i.imgur.com/8Pzv4QC.png)

上图是ahb_interface上的波形，第一次红的地方就是写数据到IP中，第二次蓝的地方就是从IP register中读数据出来，波形跟AMBA手册上的波形一模一样。

![](https://i.imgur.com/oP7kgOq.png)