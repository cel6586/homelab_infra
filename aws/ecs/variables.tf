# Tag for gametracker images in ECR
variable "image_tag" {
  description = "Image Tag (commit SHA) to deply from ECR"
  type        = string
}