#!/usr/bin/expect -f
set ip [lindex $argv 0];

spawn ssh-copy-id vagrant@$ip
expect {
        "Are you sure you want to continue connecting" {
                send "yes\r"
                exp_continue
        }
        "password:" {
                send "vagrant\r"
                exp_continue
        }
}