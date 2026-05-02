variable "name_prefix" {
  description = "Prefix for alert names (e.g. ca-gde-dev-dpa-backend)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the alerts."
  type        = string
}

variable "scopes" {
  description = "List of resource IDs to monitor (e.g. Container App resource ID)."
  type        = list(string)
}

variable "action_group_ids" {
  description = "List of Action Group IDs to notify when alert fires."
  type        = list(string)
}

# --- CPU alert (optional) ---
variable "cpu_threshold" {
  description = "Alert when CPU %% (average) is above this value. Set to null to disable."
  type        = number
  default     = null
}

variable "cpu_aggregation" {
  description = "Aggregation for CPU metric (Average, Maximum, Minimum, Total)."
  type        = string
  default     = "Average"
}

# --- Memory alert (optional) ---
variable "memory_threshold" {
  description = "Alert when Memory %% (average) is above this value. Set to null to disable."
  type        = number
  default     = null
}

variable "memory_aggregation" {
  description = "Aggregation for Memory metric."
  type        = string
  default     = "Average"
}

# --- Replica count alert (optional) ---
variable "replica_count_threshold" {
  description = "Alert when replica count is greater than this value. Set to null to disable."
  type        = number
  default     = null
}

variable "replica_aggregation" {
  description = "Aggregation for Replicas metric (Average, Total, Maximum, Minimum)."
  type        = string
  default     = "Average"
}

# --- Common ---
variable "evaluation_frequency" {
  description = "How often the metric alert is evaluated (e.g. PT1M, PT5M)."
  type        = string
  default     = "PT1M"
}

variable "window_size" {
  description = "Period over which the metric is aggregated (e.g. PT5M, PT15M)."
  type        = string
  default     = "PT5M"
}

variable "severity" {
  description = "Alert severity (0, 1, 2, 3). 0=Sev0, 1=Sev1, 2=Sev2, 3=Sev3."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags for the alert resources."
  type        = map(string)
  default     = {}
}
