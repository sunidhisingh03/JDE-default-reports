resource_group_name     = "rg-finops-prd-we-001" 
location                = "Central India"
automation_account_name = "aa-hcltools-prd-we-001"
tags = {
            application_id ="app000000"
            application_name="hcltools"
            environment_type="prd"
            business_capability="operations"
            business_impact="high"
            opco="0002"
            managed_by="terraform"
        }