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
- VM1 cannot communicate with VM2 using their private IP addresses.
- The local spoke VNets cannot communicate with the hub VNet.
- Restoring the hub-to-spoke peerings does not automatically provide spoke-to-spoke connectivity.
- Check the global connection between Italy and Spain Hub vNets 

## Troubleshooting notes

### Scenario 1: VM1 cannot communicate with VM2
- Symptoms:
- Troubleshooting tools used:
- Checks performed:
- Root cause:
- Changes applied:
- Validation:

