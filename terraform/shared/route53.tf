module "zones" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.0.0"

  zones = {
    "agenticai.co.nz" = {
      name = "agenticai.co.nz"
      tags = var.tags
    },

    "dev.agenticai.co.nz" = {
      name = "dev.agenticai.co.nz"
      tags = var.tags
    }
  }
}