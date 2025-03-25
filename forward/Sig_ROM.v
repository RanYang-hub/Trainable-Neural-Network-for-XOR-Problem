module Sig_ROM #(parameter inWidth=8, dataWidth=16) (
    input           clk,
    input   [inWidth-1:0]   x,
    output  reg [dataWidth-1:0]  out
);
    
    // 使用8位输入宽度，支持256个条目的查找表
    reg [dataWidth-1:0] sigmoid_lut [0:255];
    reg [7:0] lut_index;
    
    // 初始化硬编码的sigmoid查找表
    initial begin
        // -128到-65区间 (几乎为0)
       sigmoid_lut[0]   = 16'd0;     // -128
        sigmoid_lut[1]   = 16'd0;     // -127
        sigmoid_lut[2]   = 16'd0;     // -126
        sigmoid_lut[3]   = 16'd0;     // -125
        sigmoid_lut[4]   = 16'd0;     // -124
        sigmoid_lut[5]   = 16'd0;     // -123
        sigmoid_lut[6]   = 16'd0;     // -122
        sigmoid_lut[7]   = 16'd0;     // -121
        sigmoid_lut[8]   = 16'd0;     // -120
        sigmoid_lut[9]   = 16'd0;     // -119
        sigmoid_lut[10]  = 16'd0;     // -118
        sigmoid_lut[11]  = 16'd0;     // -117
        sigmoid_lut[12]  = 16'd0;     // -116
        sigmoid_lut[13]  = 16'd0;     // -115
        sigmoid_lut[14]  = 16'd0;     // -114
        sigmoid_lut[15]  = 16'd0;     // -113
        sigmoid_lut[16]  = 16'd0;     // -112
        sigmoid_lut[17]  = 16'd0;     // -111
        sigmoid_lut[18]  = 16'd0;     // -110
        sigmoid_lut[19]  = 16'd0;     // -109
        sigmoid_lut[20]  = 16'd0;     // -108
        sigmoid_lut[21]  = 16'd0;     // -107
        sigmoid_lut[22]  = 16'd0;     // -106
        sigmoid_lut[23]  = 16'd0;     // -105
        sigmoid_lut[24]  = 16'd0;     // -104
        sigmoid_lut[25]  = 16'd0;     // -103
        sigmoid_lut[26]  = 16'd0;     // -102
        sigmoid_lut[27]  = 16'd0;     // -101
        sigmoid_lut[28]  = 16'd0;     // -100
        sigmoid_lut[29]  = 16'd0;     // -99
        sigmoid_lut[30]  = 16'd0;     // -98
        sigmoid_lut[31]  = 16'd0;     // -97
        sigmoid_lut[32]  = 16'd0;     // -96
        sigmoid_lut[33]  = 16'd0;     // -95
        sigmoid_lut[34]  = 16'd0;     // -94
        sigmoid_lut[35]  = 16'd0;     // -93
        sigmoid_lut[36]  = 16'd0;     // -92
        sigmoid_lut[37]  = 16'd0;     // -91
        sigmoid_lut[38]  = 16'd0;     // -90
        sigmoid_lut[39]  = 16'd0;     // -89
        sigmoid_lut[40]  = 16'd0;     // -88
        sigmoid_lut[41]  = 16'd0;     // -87
        sigmoid_lut[42]  = 16'd0;     // -86
        sigmoid_lut[43]  = 16'd0;     // -85
        sigmoid_lut[44]  = 16'd0;     // -84
        sigmoid_lut[45]  = 16'd0;     // -83
        sigmoid_lut[46]  = 16'd0;     // -82
        sigmoid_lut[47]  = 16'd0;     // -81
        sigmoid_lut[48]  = 16'd0;     // -80
        sigmoid_lut[49]  = 16'd0;     // -79
        sigmoid_lut[50]  = 16'd0;     // -78
        sigmoid_lut[51]  = 16'd0;     // -77
        sigmoid_lut[52]  = 16'd0;     // -76
        sigmoid_lut[53]  = 16'd0;     // -75
        sigmoid_lut[54]  = 16'd0;     // -74
        sigmoid_lut[55]  = 16'd0;     // -73
        sigmoid_lut[56]  = 16'd0;     // -72
        sigmoid_lut[57]  = 16'd0;     // -71
        sigmoid_lut[58]  = 16'd0;     // -70
        sigmoid_lut[59]  = 16'd0;     // -69
        sigmoid_lut[60]  = 16'd0;     // -68
        sigmoid_lut[61]  = 16'd0;     // -67
        sigmoid_lut[62]  = 16'd0;     // -66
        sigmoid_lut[63]  = 16'd0;     // -65
        
        // -64到-33区间 (非常小但有值)
        sigmoid_lut[64]  = 16'd1;     // -64
        sigmoid_lut[65]  = 16'd1;     // -63
        sigmoid_lut[66]  = 16'd1;     // -62
        sigmoid_lut[67]  = 16'd1;     // -61
        sigmoid_lut[68]  = 16'd1;     // -60
        sigmoid_lut[69]  = 16'd1;     // -59
        sigmoid_lut[70]  = 16'd1;     // -58
        sigmoid_lut[71]  = 16'd1;     // -57
        sigmoid_lut[72]  = 16'd1;     // -56
        sigmoid_lut[73]  = 16'd1;     // -55
        sigmoid_lut[74]  = 16'd1;     // -54
        sigmoid_lut[75]  = 16'd1;     // -53
        sigmoid_lut[76]  = 16'd1;     // -52
        sigmoid_lut[77]  = 16'd1;     // -51
        sigmoid_lut[78]  = 16'd1;     // -50
        sigmoid_lut[79]  = 16'd1;     // -49
        sigmoid_lut[80]  = 16'd1;     // -48
        sigmoid_lut[81]  = 16'd1;     // -47
        sigmoid_lut[82]  = 16'd1;     // -46
        sigmoid_lut[83]  = 16'd1;     // -45
        sigmoid_lut[84]  = 16'd1;     // -44
        sigmoid_lut[85]  = 16'd1;     // -43
        sigmoid_lut[86]  = 16'd1;     // -42
        sigmoid_lut[87]  = 16'd1;     // -41
        sigmoid_lut[88]  = 16'd1;     // -40
        sigmoid_lut[89]  = 16'd1;     // -39
        sigmoid_lut[90]  = 16'd1;     // -38
        sigmoid_lut[91]  = 16'd1;     // -37
        sigmoid_lut[92]  = 16'd1;     // -36
        sigmoid_lut[93]  = 16'd1;     // -35
        sigmoid_lut[94]  = 16'd1;     // -34
        sigmoid_lut[95]  = 16'd1;     // -33
        
        // -32到-17区间 (逐渐增长)
        sigmoid_lut[96]  = 16'd2;     // -32
        sigmoid_lut[97]  = 16'd2;     // -31
        sigmoid_lut[98]  = 16'd2;     // -30
        sigmoid_lut[99]  = 16'd2;     // -29
        sigmoid_lut[100] = 16'd3;     // -28
        sigmoid_lut[101] = 16'd3;     // -27
        sigmoid_lut[102] = 16'd3;     // -26
        sigmoid_lut[103] = 16'd4;     // -25
        sigmoid_lut[104] = 16'd4;     // -24
        sigmoid_lut[105] = 16'd5;     // -23
        sigmoid_lut[106] = 16'd6;     // -22
        sigmoid_lut[107] = 16'd7;     // -21
        sigmoid_lut[108] = 16'd8;     // -20
        sigmoid_lut[109] = 16'd9;     // -19
        sigmoid_lut[110] = 16'd10;    // -18
        sigmoid_lut[111] = 16'd12;    // -17
        
        // -16到-9区间 (更快速增长)
        sigmoid_lut[112] = 16'd14;    // -16
        sigmoid_lut[113] = 16'd16;    // -15
        sigmoid_lut[114] = 16'd18;    // -14
        sigmoid_lut[115] = 16'd21;    // -13
        sigmoid_lut[116] = 16'd24;    // -12
        sigmoid_lut[117] = 16'd28;    // -11
        sigmoid_lut[118] = 16'd32;    // -10
        sigmoid_lut[119] = 16'd36;    // -9
        
        // -8到-5区间
        sigmoid_lut[120] = 16'd42;    // -8
        sigmoid_lut[121] = 16'd48;    // -7
        sigmoid_lut[122] = 16'd54;    // -6
        sigmoid_lut[123] = 16'd62;    // -5
        
        // -4到-1区间 (快速增长区域)
        sigmoid_lut[124] = 16'd70;    // -4
        sigmoid_lut[125] = 16'd80;    // -3
        sigmoid_lut[126] = 16'd90;    // -2
        sigmoid_lut[127] = 16'd102;   // -1
        
        // 0 (中点，sigmoid=0.5)
        sigmoid_lut[128] = 16'd128;   // 0, 0.5 in 8.8 format
        
        // 1到4区间 (快速增长区域)
        sigmoid_lut[129] = 16'd154;   // 1
        sigmoid_lut[130] = 16'd166;   // 2
        sigmoid_lut[131] = 16'd176;   // 3
        sigmoid_lut[132] = 16'd186;   // 4
        
        // 5到8区间
        sigmoid_lut[133] = 16'd194;   // 5
        sigmoid_lut[134] = 16'd202;   // 6
        sigmoid_lut[135] = 16'd208;   // 7
        sigmoid_lut[136] = 16'd214;   // 8
        
        // 9到16区间 (逐渐趋于1)
        sigmoid_lut[137] = 16'd220;   // 9
        sigmoid_lut[138] = 16'd224;   // 10
        sigmoid_lut[139] = 16'd228;   // 11
        sigmoid_lut[140] = 16'd232;   // 12
        sigmoid_lut[141] = 16'd235;   // 13
        sigmoid_lut[142] = 16'd238;   // 14
        sigmoid_lut[143] = 16'd240;   // 15
        sigmoid_lut[144] = 16'd242;   // 16
        
        // 17到32区间 (接近1)
        sigmoid_lut[145] = 16'd244;   // 17
        sigmoid_lut[146] = 16'd246;   // 18
        sigmoid_lut[147] = 16'd247;   // 19
        sigmoid_lut[148] = 16'd248;   // 20
        sigmoid_lut[149] = 16'd249;   // 21
        sigmoid_lut[150] = 16'd250;   // 22
        sigmoid_lut[151] = 16'd251;   // 23
        sigmoid_lut[152] = 16'd252;   // 24
        sigmoid_lut[153] = 16'd252;   // 25
        sigmoid_lut[154] = 16'd253;   // 26
        sigmoid_lut[155] = 16'd253;   // 27
        sigmoid_lut[156] = 16'd253;   // 28
        sigmoid_lut[157] = 16'd254;   // 29
        sigmoid_lut[158] = 16'd254;   // 30
        sigmoid_lut[159] = 16'd254;   // 31
        sigmoid_lut[160] = 16'd254;   // 32
        
        // 33到64区间 (非常接近1)
        sigmoid_lut[161] = 16'd255;   // 33
        sigmoid_lut[162] = 16'd255;   // 34
        sigmoid_lut[163] = 16'd255;   // 35
        sigmoid_lut[164] = 16'd255;   // 36
        sigmoid_lut[165] = 16'd255;   // 37
        sigmoid_lut[166] = 16'd255;   // 38
        sigmoid_lut[167] = 16'd255;   // 39
        sigmoid_lut[168] = 16'd255;   // 40
        sigmoid_lut[169] = 16'd255;   // 41
        sigmoid_lut[170] = 16'd255;   // 42
        sigmoid_lut[171] = 16'd255;   // 43
        sigmoid_lut[172] = 16'd255;   // 44
        sigmoid_lut[173] = 16'd255;   // 45
        sigmoid_lut[174] = 16'd255;   // 46
        sigmoid_lut[175] = 16'd255;   // 47
        sigmoid_lut[176] = 16'd255;   // 48
        sigmoid_lut[177] = 16'd255;   // 49
        sigmoid_lut[178] = 16'd255;   // 50
        sigmoid_lut[179] = 16'd255;   // 51
        sigmoid_lut[180] = 16'd255;   // 52
        sigmoid_lut[181] = 16'd255;   // 53
        sigmoid_lut[182] = 16'd255;   // 54
        sigmoid_lut[183] = 16'd255;   // 55
        sigmoid_lut[184] = 16'd255;   // 56
        sigmoid_lut[185] = 16'd255;   // 57
        sigmoid_lut[186] = 16'd255;   // 58
        sigmoid_lut[187] = 16'd255;   // 59
        sigmoid_lut[188] = 16'd255;   // 60
        sigmoid_lut[189] = 16'd255;   // 61
        sigmoid_lut[190] = 16'd255;   // 62
        sigmoid_lut[191] = 16'd255;   // 63
        sigmoid_lut[192] = 16'd255;   // 64
        
        // 65到127区间 (基本就是1)
        sigmoid_lut[193] = 16'd256;   // 65
        sigmoid_lut[194] = 16'd256;   // 66
        sigmoid_lut[195] = 16'd256;   // 67
        sigmoid_lut[196] = 16'd256;   // 68
        sigmoid_lut[197] = 16'd256;   // 69
        sigmoid_lut[198] = 16'd256;   // 70
        sigmoid_lut[199] = 16'd256;   // 71
        sigmoid_lut[200] = 16'd256;   // 72
        sigmoid_lut[201] = 16'd256;   // 73
        sigmoid_lut[202] = 16'd256;   // 74
        sigmoid_lut[203] = 16'd256;   // 75
        sigmoid_lut[204] = 16'd256;   // 76
        sigmoid_lut[205] = 16'd256;   // 77
        sigmoid_lut[206] = 16'd256;   // 78
        sigmoid_lut[207] = 16'd256;   // 79
        sigmoid_lut[208] = 16'd256;   // 80
        sigmoid_lut[209] = 16'd256;   // 81
        sigmoid_lut[210] = 16'd256;   // 82
        sigmoid_lut[211] = 16'd256;   // 83
        sigmoid_lut[212] = 16'd256;   // 84
        sigmoid_lut[213] = 16'd256;   // 85
        sigmoid_lut[214] = 16'd256;   // 86
        sigmoid_lut[215] = 16'd256;   // 87
        sigmoid_lut[216] = 16'd256;   // 88
        sigmoid_lut[217] = 16'd256;   // 89
        sigmoid_lut[218] = 16'd256;   // 90
        sigmoid_lut[219] = 16'd256;   // 91
        sigmoid_lut[220] = 16'd256;   // 92
        sigmoid_lut[221] = 16'd256;   // 93
        sigmoid_lut[222] = 16'd256;   // 94
        sigmoid_lut[223] = 16'd256;   // 95
        sigmoid_lut[224] = 16'd256;   // 96
        sigmoid_lut[225] = 16'd256;   // 97
        sigmoid_lut[226] = 16'd256;   // 98
        sigmoid_lut[227] = 16'd256;   // 99
        sigmoid_lut[228] = 16'd256;   // 100
        sigmoid_lut[229] = 16'd256;   // 101
        sigmoid_lut[230] = 16'd256;   // 102
        sigmoid_lut[231] = 16'd256;   // 103
        sigmoid_lut[232] = 16'd256;   // 104
        sigmoid_lut[233] = 16'd256;   // 105
        sigmoid_lut[234] = 16'd256;   // 106
        sigmoid_lut[235] = 16'd256;   // 107
        sigmoid_lut[236] = 16'd256;   // 108
        sigmoid_lut[237] = 16'd256;   // 109
        sigmoid_lut[238] = 16'd256;   // 110
        sigmoid_lut[239] = 16'd256;   // 111
        sigmoid_lut[240] = 16'd256;   // 112
        sigmoid_lut[241] = 16'd256;   // 113
        sigmoid_lut[242] = 16'd256;   // 114
        sigmoid_lut[243] = 16'd256;   // 115
        sigmoid_lut[244] = 16'd256;   // 116
        sigmoid_lut[245] = 16'd256;   // 117
        sigmoid_lut[246] = 16'd256;   // 118
        sigmoid_lut[247] = 16'd256;   // 119
        sigmoid_lut[248] = 16'd256;   // 120
        sigmoid_lut[249] = 16'd256;   // 121
        sigmoid_lut[250] = 16'd256;   // 122
        sigmoid_lut[251] = 16'd256;   // 123
        sigmoid_lut[252] = 16'd256;   // 124
        sigmoid_lut[253] = 16'd256;   // 125
        sigmoid_lut[254] = 16'd256;   // 126
        sigmoid_lut[255] = 16'd256;  
    end
    
    always @(posedge clk) begin
        // 将输入映射到查找表索引
        lut_index = $unsigned($signed(x) + 8'd128); // 将[-128,127]映射到[0,255]
        
        // 输出对应的sigmoid值
        out <= sigmoid_lut[lut_index];
    end
endmodule
