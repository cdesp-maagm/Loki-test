
proc connect_type {name} {
    set res ""

    if {$res eq ""} {set res [get_bd_intf_pins  -quiet $name]}
    if {$res eq ""} {set res [get_bd_pins       -quiet $name]}
    if {$res eq ""} {set res [get_bd_intf_ports -quiet $name]}
    if {$res eq ""} {set res [get_bd_ports      -quiet $name]}
    if {$res eq ""} {set res [get_bd_intf_nets  -quiet $name]}
    if {$res eq ""} {set res [get_bd_nets       -quiet $name]}

    return $res
}

proc connect {a b} {
    # Chercher l'objet associé à chaque connexion.
    set ca [connect_type $a]
    set cb [connect_type $b]

    # Si a n'existe pas, échanger a et b.
    if {$ca eq ""} {
        set ca $cb
        set cb ""
    }

    # Si aucun noeud n'existe pour a et b, terminer silencieusement.
    if {$ca eq ""} {
        puts "connect: Rien à faire pour $a - $b"
        return
    }

    # Ici, un noeud a été trouvé pour a.
    # Si nécessaire, créer un noeud pour b de même type que a.
    # a doit obligatoirement être de type "pin" ou "interface pin".
    if {$cb eq ""} {
        switch [get_property CLASS $ca] {
            bd_intf_pin { create_bd_intf_net $b }
            bd_pin      { create_bd_net      $b }
            default     { return }
        }
        set cb [connect_type $b]
    }

    puts "connect: Connexion de $ca ([get_property CLASS $ca]) à $cb ([get_property CLASS $cb])"

    switch [get_property CLASS $ca] {
        bd_intf_pin { connect_bd_intf_net $ca $cb }
        bd_pin {
            if {[get_property CLASS $cb] eq "bd_net"} {
                connect_bd_net -net $cb $ca
            } else {
                connect_bd_net $ca $cb
            }
        }
        bd_net { connect_bd_net -net $ca $cb}
    }
}

proc axi_connect {m s args} {
    set intc Auto
    set clk Auto
    if [dict exists $args "-clk"] {
        set clk [dict get $args "-clk"]
    }
    if [dict exists $args "-intc"] {
        set intc [dict get $args "-intc"]
    }
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config "
        Clk_master $clk
        Clk_slave $clk
        Clk_xbar $clk
        Master $m
        Slave $s
        intc_ip $intc
        master_apm 0
    " [get_bd_intf_pins $s]
}

proc diff_in {size p n out} {
    set name ibuf_${p}_${n}
    set buf [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 $name]
    set_property -dict "
        CONFIG.C_BUF_TYPE IBUFDS
        CONFIG.C_SIZE     $size
    " $buf
    connect /$name/IBUF_DS_P $p
    connect /$name/IBUF_DS_N $n
    connect /$name/IBUF_OUT $out
}

proc diff_out {size p n in} {
    set name obuf_${p}_${n}
    set buf [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 $name]
    set_property -dict "
        CONFIG.C_BUF_TYPE OBUFDS
        CONFIG.C_SIZE     $size
    " $buf
    connect /$name/OBUF_DS_P $p
    connect /$name/OBUF_DS_N $n
    connect /$name/OBUF_IN $in
}
