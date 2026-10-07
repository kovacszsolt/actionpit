variable "function_name" {
  description = "Name of the Lambda function. Used as-is, so include any project/environment prefix at the call site."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "function_name must contain only alphanumeric characters, hyphens and underscores."
  }
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = ""
}

variable "package_type" {
  description = "Deployment packaging type: \"Zip\" (requires runtime, handler and either filename or s3_bucket + s3_key) or \"Image\" (requires image_uri)."
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be either \"Zip\" or \"Image\"."
  }

  validation {
    condition = (
      var.package_type == "Zip"
      ? var.runtime != null && var.handler != null && (var.filename != null || (var.s3_bucket != null && var.s3_key != null))
      : var.image_uri != null
    )
    error_message = "For package_type \"Zip\" set runtime, handler and either filename or s3_bucket + s3_key. For package_type \"Image\" set image_uri."
  }
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. provided.al2023, python3.12, nodejs20.x). Required for Zip packages, ignored for Image."
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda function entrypoint handler (e.g. main.handler). Required for Zip packages, ignored for Image."
  type        = string
  default     = null
}

variable "architecture" {
  description = "Instruction set architecture of the function: \"arm64\" or \"x86_64\"."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be either \"arm64\" or \"x86_64\"."
  }
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the function (128-10240)."
  type        = number
  default     = 512

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Function invocation timeout in seconds (1-900)."
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "The amount of traffic to allocate to the function. Use -1 for unrestricted (account limit applies), or a value >= 1 to reserve concurrency."
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions == -1 || var.reserved_concurrent_executions >= 1
    error_message = "reserved_concurrent_executions must be -1 (unrestricted) or at least 1."
  }
}

variable "ephemeral_storage_size" {
  description = "Size of the function's /tmp directory in MiB. Lambda only supports 512 or 10240."
  type        = number
  default     = 512

  validation {
    condition     = contains([512, 10240], var.ephemeral_storage_size)
    error_message = "ephemeral_storage_size must be either 512 or 10240 MiB."
  }
}

variable "environment_variables" {
  description = "Environment variables available to the function at invocation time. Do not put secrets here unless the function truly requires them."
  type        = map(string)
  default     = {}
}

variable "filename" {
  description = "Path to the deployment package ZIP archive (Zip package_type). Conflicts with s3_bucket/s3_key. Provide source_code_hash to trigger redeployments on code changes."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the ZIP deployment package (typically filebase64sha256(var.filename))."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket holding the deployment package ZIP (Zip package_type). Requires s3_key."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 object key of the deployment package ZIP (Zip package_type). Requires s3_bucket."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Version ID of the S3 object holding the deployment package ZIP."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "Container image URI including tag or digest (Image package_type, e.g. ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/repo:tag). Must be in the same region and account as the provider."
  type        = string
  default     = null
}

variable "create_log_group" {
  description = "Whether the module creates the /aws/lambda/<function_name> log group. Disable it if the log group is managed elsewhere (retention is then not managed by this module)."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Number of days to retain Lambda logs (any CloudWatch Logs retention value, e.g. 1, 7, 14, 30, 60, 90, 180, 365; 0 = never expire). Only used when create_log_group is true."
  type        = number
  default     = 14
}

variable "create_execution_role" {
  description = "Whether the module creates the Lambda execution role. Set to false and provide execution_role_arn to use a pre-existing role."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role for the function to assume. Required when create_execution_role is false, ignored otherwise."
  type        = string
  default     = null

  validation {
    condition     = var.create_execution_role || var.execution_role_arn != null
    error_message = "execution_role_arn is required when create_execution_role is false."
  }
}

variable "execution_role_name" {
  description = "Name of the created execution role. Defaults to \"lambda-<function_name>-execution\" when null. Ignored when create_execution_role is false."
  type        = string
  default     = null
}

variable "trusted_service_principals" {
  description = "Service principals allowed to assume the created execution role. Defaults to lambda.amazonaws.com; only change for exotic setups (e.g. codebuild.amazonaws.com for CallFunction-based schedulers)."
  type        = list(string)
  default     = ["lambda.amazonaws.com"]
}

variable "managed_policy_arns" {
  description = "ARNs of managed policies to attach to the created execution role (e.g. arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole, ReadOnlyAccess, or custom policy ARNs). Ignored when create_execution_role is false."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:", arn))])
    error_message = "Every entry in managed_policy_arns must be a valid IAM policy ARN (starting with \"arn:\")."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the function's VPC configuration. Provide together with security_group_ids to attach the function to a VPC (also attach AWSLambdaVPCAccessExecutionRole via managed_policy_arns when the role is created by this module)."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.subnet_ids) == 0 && length(var.security_group_ids) == 0
      || length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0
    )
    error_message = "subnet_ids and security_group_ids must be provided together (both set or both empty)."
  }
}

variable "security_group_ids" {
  description = "Security group IDs for the function's VPC configuration. Must be provided together with subnet_ids (enforced by the subnet_ids validation)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

