variable "lambda_function_name" {
  description = "name of the lambda to be invoked"
  type        = string
}

variable "lambda_payload" {
  description = "payload for the lambda invokation"
  type = object({
    bucket_name = string
    file_name   = string
    content     = string
    }
  )
}