locals {
  subscriptions_flat = {
    for pair in flatten([
      for topic_key, topic in var.topics : [
        for sub_key, sub in coalesce(topic.subscriptions, {}) : {
          id         = "${topic_key}::${sub_key}"
          topic_key  = topic_key
          sub_key    = sub_key
          sub_config = sub
        }
      ]
    ]) : pair.id => pair
  }
}

resource "azurerm_servicebus_namespace" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  capacity = var.sku == "Premium" ? coalesce(var.capacity, 1) : coalesce(var.capacity, 0)
  premium_messaging_partitions = (
    var.sku == "Premium" ? coalesce(var.premium_messaging_partitions, 0) : null
  )

  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version

  tags = var.tags
}

resource "azurerm_servicebus_queue" "queues" {
  for_each = var.queues

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.main.id

  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
  dead_lettering_on_message_expiration = each.value.dead_lettering_on_message_expiration
  requires_session                     = each.value.requires_session
  requires_duplicate_detection         = each.value.requires_duplicate_detection
  partitioning_enabled                 = each.value.partitioning_enabled
  max_size_in_megabytes                = each.value.max_size_in_megabytes
}

resource "azurerm_servicebus_topic" "topics" {
  for_each = var.topics

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.main.id

  partitioning_enabled         = each.value.partitioning_enabled
  requires_duplicate_detection = each.value.requires_duplicate_detection
  max_size_in_megabytes        = each.value.max_size_in_megabytes
}

resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = local.subscriptions_flat

  name     = each.value.sub_key
  topic_id = azurerm_servicebus_topic.topics[each.value.topic_key].id

  max_delivery_count                   = each.value.sub_config.max_delivery_count
  dead_lettering_on_message_expiration = each.value.sub_config.dead_lettering_on_message_expiration
  batched_operations_enabled           = each.value.sub_config.batched_operations_enabled
}
