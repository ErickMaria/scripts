#!/bin/sh

sed -i "s/#host_key_checking/host_key_checking/" /etc/ansible/ansible.cfg

awk '
    {
        print"[all:vars]";
        print"ansible_connetion=ssh\n";

        print"[rancher]";
        if ($3~"^[0-9]")
        {
            print $3;
        }
        
    }    
' /terraform_output | 
awk '!a[$0]++' > hosts

awk '
    {
        split($1, names, "_");
        if (names[4] ~ /host|server/){
            print "\n[" names[4] "]";
            print $3
            print "[" names[4] ":vars" "]";
            print "ansible_ssh_user=@"names[4]"_user";
            print "ansible_ssh_pass=@"names[4]"_pass";
            print "ansible_sudo_pass=@"names[4]"_pass"
        }
    }
' /terraform_output |
awk '!a[$0]++' >> hosts

LINES=$(awk 'gsub(" ","", $0);' /terraform_output)

for LINE in $LINES;
do
    VALUE=$(echo "$LINE" | awk -F'=' '{print $2}')
    IFS='=' read -ra vrhs <<< $LINE
    
    for vrh in $vrhs;
    do
        if [[ $vrh =~ (server_user) ]]; then
            sed -i "s/@${vrh}/${VALUE}/" hosts
        elif [[ $vrh =~ (server_pass) ]]; then
            sed -i "s/@${vrh}/${VALUE}/" hosts
        elif [[ $vrh =~ (host_user) ]]; then
            sed -i "s/@${vrh}/${VALUE}/" hosts
        elif [[ $vrh =~ (host_pass) ]]; then
            sed -i "s/@${vrh}/${VALUE}/" hosts
        fi
    done;
done;

mv hosts /etc/ansible
#cat /terraform_output | grep ip
rm -f /terraform_output
