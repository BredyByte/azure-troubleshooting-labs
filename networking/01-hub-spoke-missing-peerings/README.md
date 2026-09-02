# Hub-and-spoke: missing peerings

Terraform conversion of the supplied Azure ARM template for a networking troubleshooting lab.

## Scenario

The environment contains:

- One hub VNet in Spain Central.
- Three spoke VNets in Spain Central.
- One remote VNet in Italy North.
- Global VNet peering between the Spain hub and Italy North.
- One Windows VM in spoke A and one Windows VM in spoke C.
- One NSG and one public IP for each VM.
- One VPN Gateway in the hub.

The peerings between the hub and the three local spokes are intentionally missing. This is the initial fault of the lab.

![Azure architecture](../../docs/01-hub-spoke-missing-peerings.png)

## Troubleshooting scenarios

## Troubleshooting notes


