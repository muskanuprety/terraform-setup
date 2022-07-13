terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.35"
    }
  }
}
/*"providers" in Snowflake allow you to create resources using different users/roles/accounts, in this instance we have two 
providers one for SYSADMIN, one for SECURITYADMIN, to use these, set provider = snowflake.sys/security_admin */
provider "snowflake" {
  role  = "SYSADMIN"
  alias = "sys_admin"
}

provider "snowflake" {
  role  = "SECURITYADMIN"
  alias = "security_admin"
}
/*Database creation*/
resource "snowflake_database" "db" {
    provider = snowflake.sys_admin
  name     = "TF_DEMO2"
    }
/*Creates Read/Write Access Role*/
resource "snowflake_role" "access" {
        provider = snowflake.security_admin
        name     = "_TF_RW_ROLE"
    }
/*Creates Compute Role*/
resource "snowflake_role" "compute" {
        provider = snowflake.security_admin
        name     = "_TF_COMPUTE_ROLE"
    }
/*Creates Admin Role which will have ownership of both the Access Role and Compute Role*/
resource "snowflake_role" "admin" {
        provider = snowflake.security_admin
        name     = "TF_ADMIN_ROLE"
    }
/*Granting Use of the DB to the Access Role*/
resource "snowflake_database_grant" "grant" {
        provider          = snowflake.sys_admin
        database_name     = snowflake_database.db.name
        privilege         = "USAGE"
        roles             = [snowflake_role.access.name]
        with_grant_option = false
    }
/*Creates schema on the Database*/
resource "snowflake_schema" "schema" {
        provider          = snowflake.sys_admin
        database   = snowflake_database.db.name
        name       = "TF_DEMO"
        is_managed = false
    }
/*Creates Compute Warehouse*/
resource "snowflake_warehouse" "warehouse" {
        provider          = snowflake.sys_admin
        name           = "TF_DEMO1"
        warehouse_size = "xsmall"
        auto_suspend = 60
}
/*Grants use of the warehouse to the Compute Role*/
resource "snowflake_warehouse_grant" "grant" {
        provider          = snowflake.sys_admin
        warehouse_name    = snowflake_warehouse.warehouse.name
        privilege         = "USAGE"
        roles             = [snowflake_role.compute.name]
        with_grant_option = false
    }
/*Should create user, but currently doesn't*/
resource "snowflake_user" "user" {
        provider          = snowflake.security_admin
        name              = "tf_demo_user"
        password = "dvneksFkgMF"
        default_warehouse = snowflake_warehouse.warehouse.name
        default_role      = snowflake_role.admin.name
}
/*Grants Access Role to Admin Role*/
resource "snowflake_role_grants" "adminrw" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.access.name
        roles     = [snowflake_role.admin.name]
    }
/*Grants Compute Role to Admin Role*/
resource "snowflake_role_grants" "adminc" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.compute.name
        roles     = [snowflake_role.admin.name]
    }
/*Grants Admin Role to User*/
resource "snowflake_role_grants" "user" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.admin.name
        users     = [snowflake_user.user.name]
    }
/*Grants Admin Role to SYSADMIN*/
resource "snowflake_role_grants" "sysadmingrant" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.admin.name
        roles     = ["SYSADMIN"]
    }
