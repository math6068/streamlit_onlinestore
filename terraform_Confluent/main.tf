# The provider will pull credentials from two environment variables:
provider "confluent" {
}

resource "confluent_environment" "streamdb" {
  display_name = "streamdb"
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AWS"
  region  = "us-east-2"
  package = "ADVANCED"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package

  environment {
    id = confluent_environment.streamdb.id
  }

  region {
    id = data.confluent_schema_registry_region.essentials.id
  }
}

resource "confluent_kafka_cluster" "inventory" {
  display_name = "inventory"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  # Standard supports granular RBAC for admin, producer, consumer service accounts
  standard {}
  environment {
    id = confluent_environment.streamdb.id
  }
}

resource "confluent_service_account" "admin_test" {
  display_name = "admin_test"
  description  = "Cluster management service account"
}

resource "confluent_role_binding" "admin" {
  principal   = "User:${confluent_service_account.admin_test.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.inventory.rbac_crn
}

resource "confluent_api_key" "admin" {
  display_name = "admin"
  description  = "Kafka API Key owned by the 'admin' service account"
  owner {
    id          = confluent_service_account.admin_test.id
    api_version = confluent_service_account.admin_test.api_version
    kind        = confluent_service_account.admin_test.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.inventory.id
    api_version = confluent_kafka_cluster.inventory.api_version
    kind        = confluent_kafka_cluster.inventory.kind

    environment {
      id = confluent_environment.streamdb.id
    }
  }

  # Wait until the necessary role has been bound to the service account,
  # to avoid race condition with topic creation
  depends_on = [
    confluent_role_binding.admin
    #confluent_kafka_acl.admin
  ]
}

resource "confluent_kafka_acl" "app-connector-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.admin_test.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.inventory.rest_endpoint
  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }
  resource_type = "TOPIC"
  resource_name = local.database_server_name
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.admin_test.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.inventory.rest_endpoint
  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }
  resource_type = "TOPIC"
  resource_name = local.database_server_name
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.admin_test.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.inventory.rest_endpoint
  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_topic" "products" {
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }
  topic_name       = "database-st.online_store.products"
  rest_endpoint    = confluent_kafka_cluster.inventory.rest_endpoint
  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_connector" "mysql_source_connector" {
  environment {
    id = confluent_environment.streamdb.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.inventory.id
  }

  config_sensitive = {
    "database.password" = "**********"
  }

  //https://docs.confluent.io/cloud/current/connectors/cc-mysql-source-cdc-debezium.html#step-2-list-the-connector-configuration-properties
  config_nonsensitive = {
    "connector.class"          = "MySqlCdcSource"
    "name"                     = "MySqlCdcSourceConnector_0"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.admin_test.id
    "database.hostname"        = "****"
    "database.port"            = "****"
    "database.user"            = "*****"
    "database.dbname"          = "*****"
    "database.server.name"     = "*****"
    "snapshot.mode"            = "initial"
    "output.data.format"       = "AVRO"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connector-describe-on-cluster,
    confluent_kafka_acl.app-connector-write-on-prefix-topics,
    confluent_kafka_acl.app-connector-create-on-prefix-topics,
  ]

}
locals {
  database_server_name = "database-st"
}