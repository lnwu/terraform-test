package main

import (
	"github.com/hashicorp/terraform-plugin-sdk/helper/schema"
)

func Provider() *schema.Provider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"api_token": {
				Type:     schema.TypeString,
				Required: true,
			},
			"email": {
				Type:    schema.TypeString,
				Default: "",
			},
		},
		ResourcesMap: map[string]*schema.Resource{
			"example_server": resourceServer(),
		},
	}
}
