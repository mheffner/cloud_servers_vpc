module OpenvpnConfig

require 'erb'
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

          bootf = File.read(File.join(File.dirname(__FILE__), "bootstrap.sh.erb"))
          script = ""
          b = binding
          ERB.new(bootf, 0, "", "script").result(b)
return Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

end

end
