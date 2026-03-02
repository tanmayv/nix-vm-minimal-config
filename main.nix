# This is a Terranix file that generates Terraform configuration.
# To use it, run `terranix build` in this directory.

{ lib }:

let
  # --- Configuration ---
  # Replace these placeholders with your actual GCP details.

  gcp-project-id = "your-gcp-project-id";
  gcp-region     = "your-gcp-region";
  gcp-zone       = "your-vm-zone";

  # This is the label used to identify your NixOS VMs.
  # It should match the label you've set on your instances.
  nixos-vm-label-filter = "labels.nixos-vm = true";

in
{
  # 1. Configure the Google Provider
  providers.google = {
    project = gcp-project-id;
    region  = gcp-region;
  };

  # 2. Find all VM instances with the specified label
  data.google_compute_instances.nixos_vms = {
    filter = nixos-vm-label-filter;
    zone   = gcp-zone;
  };

  # 3. Fetch detailed data for each discovered VM
  # Terranix uses the 'for_each' attribute to create multiple data source
  # instances based on the list of VM names from the previous step.
  data.google_compute_instance.vm_details = {
    for_each = "toset(data.google_compute_instances.nixos_vms.instances.*.name)";
    name     = "each.key"; # 'each.key' refers to each VM name in the for_each set
    zone     = gcp-zone;
  };

  # 4. Output the parsed generation data for all VMs
  output.all_nixos_generations = {
    description = "A map of NixOS generations for all selected VMs.";

    # This is a Terraform expression that will be embedded in the final JSON.
    # It iterates over the map of VMs from the previous data source,
    # safely decodes the 'vm_generations' JSON attribute, and maps
    # each VM name to its generation data.
    value = ''
      {
        for vm_name, vm_data in data.google_compute_instance.vm_details :
        vm_name => jsondecode(try(vm_data.guest_attributes["vm_generations"], "null"))
      }
    '';
  };
}
