# ---------------------------------------------------------------------------
# HTTP endpoint / DNS
# ---------------------------------------------------------------------------

variable "hostname" {
  description = "Public HTTPS hostname served by CloudFront (e.g. api.scanner.example.com)."
  type        = string
}

variable "zone_name" {
  description = "Route53 hosted zone name (e.g. example.com)."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for ACM validation and alias records."
  type        = string
}

variable "additional_hostnames" {
  description = "Extra CloudFront aliases and ACM SANs. DNS for these hostnames is managed outside this module."
  type        = list(string)
  default     = []
}

variable "managed_hostnames" {
  description = "Extra CloudFront aliases and ACM SANs in the same Route53 zone; DNS alias + ACM validation records are created."
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "comment" {
  description = "CloudFront distribution comment."
  type        = string
  default     = null
  nullable    = true
}

# ---------------------------------------------------------------------------
# Lambda (create or reference existing)
# ---------------------------------------------------------------------------

variable "create_lambda" {
  description = "Whether this module creates the Lambda function via the aws/lambda submodule. When false, function_name must refer to an existing function."
  type        = bool
  default     = true
}

variable "function_name" {
  description = "Lambda function name. Required always: names the created function when create_lambda is true, or selects an existing function when false."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "function_name must contain only alphanumeric characters, hyphens and underscores."
  }
}

variable "description" {
  description = "Description of the Lambda function. Ignored when create_lambda is false."
  type        = string
  default     = ""
}

variable "package_type" {
  description = "Deployment packaging type: \"Zip\" or \"Image\". Ignored when create_lambda is false."
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be either \"Zip\" or \"Image\"."
  }
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. provided.al2023). Required for Zip packages when create_lambda is true."
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda handler (e.g. bootstrap). Required for Zip packages when create_lambda is true."
  type        = string
  default     = null
}

variable "architecture" {
  description = "Instruction set architecture: \"arm64\" or \"x86_64\". Ignored when create_lambda is false."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be either \"arm64\" or \"x86_64\"."
  }
}

variable "memory_size" {
  description = "Memory in MB allocated to the function (128-10240). Ignored when create_lambda is false."
  type        = number
  default     = 512

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Function invocation timeout in seconds (1-900). Ignored when create_lambda is false."
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency (-1 = unrestricted). Ignored when create_lambda is false."
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions == -1 || var.reserved_concurrent_executions >= 1
    error_message = "reserved_concurrent_executions must be -1 (unrestricted) or at least 1."
  }
}

variable "ephemeral_storage_size" {
  description = "Size of /tmp in MiB (512 or 10240). Ignored when create_lambda is false."
  type        = number
  default     = 512

  validation {
    condition     = contains([512, 10240], var.ephemeral_storage_size)
    error_message = "ephemeral_storage_size must be either 512 or 10240 MiB."
  }
}

variable "environment_variables" {
  description = "Environment variables for the function. Ignored when create_lambda is false."
  type        = map(string)
  default     = {}
}

variable "filename" {
  description = "Path to the deployment package ZIP. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the ZIP package. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket for the deployment package ZIP. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 object key for the deployment package ZIP. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version for the deployment package ZIP. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "Container image URI (Image package_type). Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "create_log_group" {
  description = "Whether the aws/lambda submodule creates the CloudWatch log group. Ignored when create_lambda is false."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days. Ignored when create_lambda is false."
  type        = number
  default     = 14
}

variable "create_execution_role" {
  description = "Whether the aws/lambda submodule creates the execution role. Ignored when create_lambda is false."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "Existing execution role ARN when create_execution_role is false in the aws/lambda submodule."
  type        = string
  default     = null
}

variable "execution_role_name" {
  description = "Name of the created execution role. Ignored when create_lambda is false."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Extra managed policies for the created execution role. Ignored when create_lambda is false."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:", arn))])
    error_message = "Every entry in managed_policy_arns must be a valid IAM policy ARN (starting with \"arn:\")."
  }
}

variable "subnet_ids" {
  description = "VPC subnet IDs. Provide together with security_group_ids. Ignored when create_lambda is false."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "VPC security group IDs. Provide together with subnet_ids. Ignored when create_lambda is false."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Function URL
# ---------------------------------------------------------------------------

variable "invoke_mode" {
  description = "How the Lambda function URL responds: BUFFERED or RESPONSE_STREAM (required for aws-lambda-go lambdaurl)."
  type        = string
  default     = "RESPONSE_STREAM"

  validation {
    condition     = contains(["BUFFERED", "RESPONSE_STREAM"], var.invoke_mode)
    error_message = "invoke_mode must be BUFFERED or RESPONSE_STREAM."
  }
}

variable "function_url_qualifier" {
  description = "Lambda alias or $LATEST for the function URL. Leave null for the unqualified function."
  type        = string
  default     = null
  nullable    = true
}

variable "cors" {
  description = "CORS settings for the Lambda function URL (browser clients calling the custom domain via CloudFront)."
  type = object({
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}
