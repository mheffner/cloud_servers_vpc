module OpenvpnConfig

require 'util/ssh'

module Bootstrap

	# Cloud servers by default do not have OpenVPN.
	# This function takes care of the installation on various distros.
	def install_openvpn

		epel_base_url_add_command=""
        if not ENV['EPEL_BASE_URL'].nil?
            ENV['EPEL_BASE_URL']
			epel_base_url_add_command="sed -e \"s|#baseurl=EPEL_BASE_URL|baseurl=#{ENV['EPEL_BASE_URL']}|g\" -i /etc/yum.repos.d/epel.repo"
        end

		#script = "rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-3.noarch.rpm && yum install -y openvpn"
        script=<<-SCRIPT_EOF
		if [ -f /etc/fedora-release ]; then
			yum install -y openvpn
		elif [ -f /etc/redhat-release ]; then
			cat > /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL <<-"EOF_CAT"
			#{IO.read(File.join(File.dirname(__FILE__), "RPM-GPG-KEY-EPEL"))}
			EOF_CAT
			cat > /etc/yum.repos.d/epel.repo <<-"EOF_CAT"
			#{IO.read(File.join(File.dirname(__FILE__), "epel.repo"))}
			EOF_CAT
			#{epel_base_url_add_command}
			yum install -y openvpn
		elif [ -f /etc/debian_version -a `lsb_release -cs` == "hardy" ]; then
			# Hardy image needs an update
			DEBIAN_FRONTEND=noninteractive apt-get update

			DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn &> /dev/null || { echo "Failed to install OpenVPN via apt-get on $HOSTNAM
			# No chkconfig on Ubuntu 8.04
			cat > /sbin/chkconfig <<-"EOF_CAT"
			#!/bin/bash
			if [ \$2 == "on" ]; then
				update-rc.d \$1 defaults
			else
				update-rc.d -f \$1 remove
			fi
			EOF_CAT
			chmod +x /sbin/chkconfig
		elif [ -f /etc/debian_version ]; then
			DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn &> /dev/null || { echo "Failed to install OpenVPN via apt-get on $HOSTNAME."; exit 1; }
			DEBIAN_FRONTEND=noninteractive apt-get install -y chkconfig &> /dev/null || { echo "Failed to install chkconfig via apt-get on $HOSTNAME."; exit 1; }
		else
			echo "Unable to install openvpn package."
			exit 1
		fi
		SCRIPT_EOF
          File.open("/tmp/openvpn_script_#{rand 999}", "w") do |f|
            f << script
          end
return Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

end

end
