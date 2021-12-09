variable "project_id" {
    description = "A GCP Project ID within your Organzation that you want Orca Security to scan"
    type = string
}

variable "organization_id" {
    description = "The numeric GCP Organization ID you would like to scan"
    type = number
}
