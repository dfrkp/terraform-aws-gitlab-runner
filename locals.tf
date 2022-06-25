locals {
  // Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",\"amazonec2-metadata-token=${var.docker_machine_instance_metadata_options.http_tokens}\", \"amazonec2-metadata-token-response-hop-limit=${var.docker_machine_instance_metadata_options.http_put_response_hop_limit}\",%s",
    join(",", formatlist("%q", concat(var.docker_machine_options, local.runners_docker_registry_mirror_option))),
  )

  runners_docker_registry_mirror_option = var.runners_docker_registry_mirror == "" ? [] : ["engine-registry-mirror=${var.runners_docker_registry_mirror}"]

  runners_docker_options = var.runners_docker_options != null ? local.runners_docker_options_map_string : local.runners_docker_options_single_string
  # TODO add all other variables
  runners_docker_options_map_string    = <<-EOT
            disable_cache = %{if var.runners_docker_options.disable_cache != null} ${var.runners_docker_options.disable_cache} %{else} false %{endif}
            image         = %{if var.runners_docker_options.image != null} ${var.runners_docker_options.image} %{else} "docker:18.03.1-ce" %{endif}
            privileged    = %{if var.runners_docker_options.privileged != null} ${var.runners_docker_options.privileged} %{else} true %{endif}
            pull_policy   = %{if var.runners_docker_options.pull_policy != null} ${var.runners_docker_options.pull_policy} %{else} "always" %{endif}
            shm_size      = %{if var.runners_docker_options.shm_size != null} ${var.runners_docker_options.shm_size} %{else} 0 %{endif}
            tls_verify    = %{if var.runners_docker_options.tls_verify != null} ${var.runners_docker_options.tls_verify} %{else} false %{endif}
            volumes       = %{if var.runners_docker_options.volumes != null} [${local.runners_docker_volumes}] %{else} ["/cache"] %{endif}
          EOT
  runners_docker_volumes               = join(", ", formatlist("\"%s\"", concat(["/cache"], var.runners_additional_volumes)))
  runners_docker_options_single_string = <<-EOT
    tls_verify = false
    image = "${var.runners_image}"
    privileged = ${var.runners_privileged}
    disable_cache = ${var.runners_disable_cache}
    volumes = [${local.runners_docker_volumes}]
    shm_size = ${var.runners_shm_size}
    pull_policy = "${var.runners_pull_policy}"
    runtime = "${var.runners_docker_runtime}"
    helper_image = "${var.runners_helper_image}"
  EOT

  // Ensure max builds is optional
  runners_max_builds_string = var.runners_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runners_max_builds)

  // Define key for runner token for SSM
  secure_parameter_store_runner_token_key  = "${var.environment}-${var.secure_parameter_store_runner_token_key}"
  secure_parameter_store_runner_sentry_dsn = "${var.environment}-${var.secure_parameter_store_runner_sentry_dsn}"

  // Custom names for runner agent instance, security groups, and IAM objects
  name_runner_agent_instance = var.overrides["name_runner_agent_instance"] == "" ? local.tags["Name"] : var.overrides["name_runner_agent_instance"]
  name_sg                    = var.overrides["name_sg"] == "" ? local.tags["Name"] : var.overrides["name_sg"]
  name_iam_objects           = lookup(var.overrides, "name_iam_objects", "") == "" ? local.tags["Name"] : var.overrides["name_iam_objects"]
  runners_additional_volumes = <<-EOT
  %{~if var.runners_add_dind_volumes~},"/certs/client", "/builds", "/var/run/docker.sock:/var/run/docker.sock"%{endif~}%{~for volume in var.runners_additional_volumes~},"${volume}"%{endfor~}
  EOT

  runners_machine_autoscaling = templatefile("${path.module}/template/runners_machine_autoscaling.tpl", {
    runners_machine_autoscaling = var.runners_machine_autoscaling
    }
  )
}
