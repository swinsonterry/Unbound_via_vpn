#!/bin/sh

Check_Tun11_Con() {
         ping -c1 -w1 -I tun11 1.1.1.1
}

Delete_Rules() {
        iptables-save | grep "unbound_rule" | sed 's/^-A/iptables -t mangle -D/' | while read CMD;do $CMD;done
}

Add_Rules(){
        iptables -t mangle -A OUTPUT -d "${wan0_dns##*.*.*.* }"/32 -p udp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x8000/0x8000
        iptables -t mangle -A OUTPUT -d "${wan0_dns%% *.*.*.*}"/32 -p udp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x8000/0x8000
        iptables -t mangle -A OUTPUT -d "${wan0_dns##*.*.*.* }"/32 -p tcp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x8000/0x8000
        iptables -t mangle -A OUTPUT -d "${wan0_dns%% *.*.*.*}"/32 -p tcp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x8000/0x8000
        iptables -t mangle -A OUTPUT -p tcp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x1000/0x1000
        iptables -t mangle -A OUTPUT -p udp --dport 53 -m comment --comment unbound_rule -j MARK --set-mark 0x1000/0x1000
}

Call_unbound_manager() {
        /jffs/addons/unbound/unbound_manager.sh vpn="$1"
}

Poll_Tun11() {
        timer=$1
        [ -z $timer ] && Post_log "Error Timeout" && exit 1 || sleep 2
        Check_Tun11_Con && Add_Rules && Call_unbound_manager "1" || Poll_Tun11 "$((timer--))"
}

Post_log() {
        $(logger -st "($(basename "$0"))" $$ "$1")
}

[ -z "$1" ] && Post_log "Script Arg Missing" && exit 1 || Post_log "Starting Script Execution"
wan0_dns="$(nvram get wan0_dns)"
Delete_Rules
        case "$1" in
                start)
                        Poll_Tun11 "150" && Post_log "Ending Script Execution" && exit 0;;
                stop)
                        Call_unbound_manager "disable" && Post_log "Ending Script Execution" && exit 0;;
                *)
                        Post_log "Script Arg Invalid" && exit 1;;
        esac
