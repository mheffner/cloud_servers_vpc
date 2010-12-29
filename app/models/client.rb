require 'async_exec'
require 'util/ip_validator'

class Client < ActiveRecord::Base

	include Util::IpValidator

	attr_accessor :num_vpn_network_interfaces

	belongs_to :server_group
	validates_presence_of :name, :description, :server_group_id
	validates_numericality_of :server_group_id
    has_many :vpn_network_interfaces, :as => :interfacable, :dependent => :destroy
	validates_format_of :name, :with => /^[A-Za-z0-9\-\.]+$/, :message => "Client name must use valid hostname characters (A-Z, a-z, 0-9, dash)."
	validates_length_of :name, :maximum => 255
	validates_length_of :description, :maximum => 255

	def validate

		count=0

		if new_record? then
			count=Client.count(:conditions => ["server_group_id = ? AND name = ?", self.server_group_id, self.name])
		else
			count=Client.count(:conditions => ["server_group_id = ? AND name = ? AND id != ?", self.server_group_id, self.name, self.id])
		end
		count+=Server.count(:conditions => ["server_group_id = ? AND name = ?", self.server_group_id, self.name])

		if count > 0 then
			errors.add_to_base("Client name '#{self.name}' is already used in this server group.")
		end

	end

	def after_create

		if self.num_vpn_network_interfaces.nil?
			self.num_vpn_network_interfaces=1
		end

		self.num_vpn_network_interfaces.to_i.times do |i|
			transaction do
				sg=self.server_group
				ips=[sg.next_ip, sg.next_ip]

				if self.is_windows then
					until (!range_endpoint?(ips[0]) and !range_endpoint?(ips[1])) do
						ips=[ips[1], sg.next_ip]
					end
				end
				sg.last_used_ip_address = IPAddr.new(sg.ip_inc_last_used_ip_address.to_i, Socket::AF_INET).to_s
				sg.save!
				VpnNetworkInterface.create(
					:vpn_ip_addr => ips[0],
					:ptp_ip_addr => ips[1],
					:interfacable_id => self.attributes["id"],
					:interfacable_type => 'Client'
				)
			end
		end
	
	end

=begin
	def make_historical
		if not self.cloud_server_id_number.nil? then
			delete_cloud_server(self.cloud_server_id_number)
		end
		update_attribute(:historical, true)
	end
=end

end
