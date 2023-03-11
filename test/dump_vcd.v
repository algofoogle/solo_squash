module dump_vcd();
    initial begin
        $dumpfile ("solo_squash.vcd");
        $dumpvars (0, solo_squash);
        // Course examples also do a #1 delay here... is that necessary?
    end
endmodule
