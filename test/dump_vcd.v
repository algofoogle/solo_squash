module dump_vcd();
    initial begin
        $dumpfile ("solo_squash.vcd");
        $dumpvars (0, solo_squash);
    end
endmodule
