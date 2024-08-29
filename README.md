Overview
The Playground will guide you through using the recently released Terraform Test. A scenario has been created where you will develop a module that is being used by 2 different projects. We'll see how simple untested changes can easily break our modules and how Terraform Test can help us reduce these occurances.

If you fall behind or believe you've made a mistake when making changes to the module, can bring yourself back up to date by going to the steps directory and using the code for the relevant step.

# 1.Setup
First thing we need to do is deploy our 2 applications which are both using our local S3 module. Once they're set up, we can begin implementing the features requested by each application and then implement.

## 1.1a Deploy Application A
Firstly, we need to set some of values for the variables that will be universal

FirsTo deploy Application A, we need to init Terraform and run an apply.

```bash
cd $work_dir/project_a && terraform init
```

Then apply the Terraform configuration:

```bash
terraform apply --auto-approve
```

You can now check that the application is deployed by going to the url for the website
```
http://[panda_name]-project-a.devopsplayground.org.s3-website-eu-west-2.amazonaws.com"
```

## 1.1b Deploy Application B
FirsTo deploy Application A, we need to init Terraform and run an apply.

```bash
cd $work_dir/project_b && terraform init
```

Then apply the Terraform configuration:

```bash
terraform apply --auto-approve
```

You can now check that the application is deployed by going to the url for the website in the outputs
```
http://[panda_name]-project-b.devopsplayground.org.s3-website-eu-west-2.amazonaws.com"
```

# 2. Feature: Error Page
Project A has requested that we add an Error page option to our module. We are going to do this without Terraform Test as an example of how a small and simple change can exexpectedly break existing functionality

## 2.1 Add Error Page Feature
To add an error 404 page we will need to add the follow resources to the **module/main.tf** file

```hcl
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.this.id
  key          = "error.html"
  source       = var.error_html_path  # Path to the error document file
  content_type = "text/html"
}
```
This will take a local error.html file and upload to the S3 bucket as a html object. If a user navigates to a non-existent page, they will be presented with the error.html

Add the following new variable to the **module/variables.tf** file

```hcl
variable "error_html_path" {
  description = "Path to the custom error document file to upload (e.g., 404.html)."
  type        = string
}
```

The new feature is now available to use for Project A. Create a new file in Project A's html directory
```bash
touch $work_dir/project_a/html/error.html
```
Add the following html to the new **project_a/html/error.html** file
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Error 404</title>
  </head>
  <body>
    <h1>Page not found</h1>
  </body>
</html>
```
Add the following argument to the **S3** module in project_a/main.tf
```hcl
error_html_path = "html/error.html"
```
We can now apply the changes to our module for Project A
```bash
cd $work_dir/project_a && terraform apply --auto-approve
```

We can see that our changes have applied successfully. If you navigate to the link in the output you will see the index.html page. Add a page that doesn't exist to the end of the url and this should show us our new error page.

Project B doesn't want to implement this feature and to keep using the module as they currently are. Let's run a plan to check there are no changes.
```bash
cd $work_dir/project_b && terraform plan
```

Our plan has returned an error! This is because our new feature hasn't been created to be optional. Let's fix that but first, we'll set up Terraform Test and write our tests

## 2.2 Terraform Test
When we run **terraform test**, it will look for test files within the root directory or, if it exists, within the **tests** directory. We will create a **tests** directory and our first test file
```bash
mkdir $work_dir/module/tests && touch $work_dir/module/tests/website.tftest.hcl
```
One of the things we can do with Terraform Test is create supporting resources to satisfy the dependancies of our modules. Let's create a **setup** directory to put our supporting Terraform resources in.
```bash
mkdir $work_dir/module/tests/setup && touch $work_dir/module/tests/setup/main.tf
```
Then add the following terraform code to **module/tests/setup/main.tf**
```hcl
terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

resource "random_pet" "random_prefix" {
  length = 4
}

output "random_prefix" {
    value = random_pet.random_prefix.id
}
```
Then we need to add module/tests/html/index.html and module/tests/html/error.html files for our module to use during the tests.
```bash
mkdir $work_dir/module/tests/html && touch $work_dir/module/tests/html/index.html && touch $work_dir/module/tests/html/error.html
```
Add the following to index.html:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>DevOps Playground</title>
  </head>
  <body>
    <h1>Welcome to the DevOps Playground</h1>
    <p>This is a test page for our DevOps Playground</p>
  </body>
</html>
```
And the following to error.html
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Error 404</title>
  </head>
  <body>
    <h1>Page not found</h1>
  </body>
</html>
```
Finally, let's add the tests to our **website.tftest.hcl** test file. These tests are for the very initial feature of a module without an error page.
```hcl
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

variables {
  index_html_path = "./tests/html/index.html"
}

run "create_bucket" {
  variables {
    panda_name = run.setup_tests.random_prefix
    domain     = "devopsplayground.org"
  }

  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.this.bucket == "${var.panda_name}.${var.domain}"
    error_message = "Invalid bucket name"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./tests/html/index.html")
    error_message = "Invalid eTag for index.html"
  }
}
```
Terraform test files are executed sequentially. So we start with our setup run block to create our randomised prefix. Next we have a variable block which will default the variable values for the whole test file. Variables defined at the inner-most scope will take precendent so these could be overridden by declaring the same variables within a run block with different values.

Lastly, we have the create_bucket run block. This starts by defining additional variables followed by 2 assert blocks that tests the logic of our Terraform deployment. The first assert block checks that the bucket name is what we expect based on the variables we provided. If this returns false, the test will fail and the error message "Invalid bucket name" is returned. The 2nd assert block checks that the index.html file that we uploaded exists and is the same content as what is in s3.

```bash
cd $work_dir/module && terraform init && terraform test
```
You should then see the following output in your terminal
```bash
tests/website.tftest.hcl... in progress
  run "setup_tests"... pass
  run "create_s3_website"... fail
╷
│ Error: No value for required variable
│ 
│   on variables.tf line 7:
│    7: variable "error_html_path" {
│ 
│ The module under test for run block "create_s3_website" has a required variable "error_html_path" with no set value. Use a -var or -var-file
│ command line argument or add this variable into a "variables" block within the test file or run block.
╵
tests/website.tftest.hcl... tearing down
tests/website.tftest.hcl... fail
```
Let's fix our module and then run the tests again. First we need to give a default value to our variable to make it optional
```hcl
variable "error_html_path" {
  description = "Path to the custom error document file to upload (e.g., 404.html)."
  type        = string
  default     = null
}
```
Then we need to update our s3 object resource to conditionally create depending on if a value is provided for error_html_path
```hcl
resource "aws_s3_object" "error" {
  count = var.error_html_path == null ? 0 : 1
  
  bucket       = aws_s3_bucket.this.id
  key          = "error.html"
  source       = var.error_html_path
  content_type = "text/html"
}
```
Now rerun our tests and they should pass
```bash
cd $work_dir/module && terraform test
```

Finally, let's check that project_b will now plan
```bash
cd $work_dir/project_b && terraform plan
```

# 3. CloudFront HTTPS Website
Project B would like the module to allow them to secure their website hosted on S3 using HTTPS.

To achieve this, we can use CloudFront (this was covered in our May 2024 DevOps Playground https://github.com/DevOpsPlayground/deploying-hugo-website/tree/main). We have already completed Step 1 by creating S3 buckets, so we now need to create ACM Certificate resources followed by CloudFront.

## 3.1a ACM
First start by creating a new acm.tf file in the module for our acm resources
```bash
touch $work_dir/module/acm.tf
```
Firstly, let's create a new variable that we can use to help conditionally create our new feature so we can avoid the same issue we faced when adding the error page to our S3 bucket. Add the following to module/variables.tf
```hcl
variable "deploy_cloudfront" {
  description = "Boolean. If set to true, module will deploy a CloudFront distribution"
  type        = bool
  default     = false
}
```
Then copy and paste the following Terraform configuration into the newly created module/acm.tf
```hcl
resource "aws_acm_certificate" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  domain_name       = local.url
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  name = var.domain
}

resource "aws_route53_record" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.this[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}
```
## 3.1b ACM - Terraform Test

Add the following to run block to module/tests/website.tftest.hcl
```hcl
run "create_acm_certificate" {
  variables {
    panda_name        = run.setup_tests.random_prefix
    index_html_path   = "./tests/html/index.html"
    error_html_path   = "./tests/html/error.html"
    domain            = "devopsplayground.org"
    deploy_cloudfront = true
  }

  assert {
    condition       = aws_acm_certificate.this[0].domain_name == "${var.panda_name}.${var.domain}"
    error_message = "Invalid FQDN for ACM certificate"
  }

  assert {
    condition       = length(split("${var.panda_name}.${var.domain}", aws_route53_record.this[0].fqdn)) > 1
    error_message = "Invalid FQDN for record"
  }
}
```

Now run Terraform Test again and these should pass
```bash
cd $work_dir/module && terraform test
```

## 3.2a CloudFront

```bash
touch $work_dir/module/cloudfront.tf
```

Add the following to **module/cloudfront.tf**
```hcl
resource "aws_cloudfront_origin_access_control" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  name                              = "oac for ${var.panda_name}"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = var.deploy_cloudfront ? 1 : 0

  enabled             = true
  comment             = "CDN for ${var.panda_name}"
  default_root_object = "index.html"

  aliases = [local.url]

  price_class = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.this[0].arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = aws_s3_bucket.this.bucket_regional_domain_name

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }
}

resource "aws_route53_record" "cloudfront_alias" {
  count = var.deploy_cloudfront ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = local.url
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this[0].domain_name
    zone_id                = aws_cloudfront_distribution.this[0].hosted_zone_id
    evaluate_target_health = false
  }
}
```

add the following outputs to module/outputs.tf
```hcl
output "website_url" {
  value = "https://${local.url}"
}

output "cloudfront_distribution_id" {
  value = try(aws_cloudfront_distribution.this[0].id, "")
}
```

## 3.2b CloudFront - Terraform Test
Because CloudFront can have a long provisioning time, we are going to limit these tests to plans only. This will ensure our tests pass or fail quickly however the trade-off is the scope of the test is reduced.

Create a new CloudFront test file:
```bash
touch $work_dir/module/tests/cloudfront.tftest.hcl
```

Add the following Terraform configuration to the new file **module/tests/cloudfront.tftest.hcl**
```hcl
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

provider "aws" {
  region = "us-east-1"
}

override_resource {
  target = aws_route53_record.this[0]
}

override_resource {
  target = aws_acm_certificate.this[0]
}

run "create_cloudfront" {
  command = plan
  variables {
    panda_name        = run.setup_tests.random_prefix
    index_html_path   = "./tests/html/index.html"
    error_html_path   = "./tests/html/error.html"
    domain            = "devopsplayground.org"
    deploy_cloudfront = true
  }
}
```
Because we are now creating CloudFront resources that didn't previously exist when we were testing the ACM resources, we should also add the following **override_resource** blocks before the ACM run block. This will mock the cloudfront resources as all we are interested in is the ACM functionality.

As we are doing an **apply** for ACM but only a **plan** for CloudFront, this is why we are testing separately and using the overrides.

```hcl
override_resource {
  target = aws_cloudfront_distribution.this[0]
}

override_resource {
  target = aws_route53_record.cloudfront_alias[0]
}
```

Then run the test
```bash
cd $work_dir/module && terraform test
```

Now let's deploy our module for project_a. Add the following argument to the **s3** module block
```hcl
deploy_cloudfront = true
````

Now let's apply the changes
```bash
cd $work_dir/project_a && terraform init && terraform apply --auto-approve
```
Finally, let's check that project_b plans with no changes
```bash
cd $work_dir/project_a && terraform init && terraform plan
```

# 4. (Optional) Terraform Cloud
You can test deploying this module to a HCP Terraform registry. We will use the DevOps Playground Gitlab repo and point the module to the complete Terraform configuration in steps/3-Cloud-Front. Optionally, you can fork the this repo to your own Github account.

Requirements:
- HCP Account
    - signup: https://developer.hashicorp.com/sign-up
    - login: https://portal.cloud.hashicorp.com/sign-in
- AWS Account (if not following along with lab)

Optional:
- Github Account

## 4.1 Create Module in HCP Terraform
Sign in to HCP then go to Terraform Cloud: app.terraform.io/app

Select your organisation or create one if it doesn't exist

Using the left-hand menu, select **Registry**

Then click the button **Publish** > **Module**

Select the **Github** provider, then input in the box ```jaykeHarrison/terraform-aws-terraform-test```

On the **Add Module** screen, choose **Branch** for the module publish type and provide the following values:
- Module Publish Type: Branch
- Branch Name: "HCP"
- Module Version: "1.0.0"

Check **Enable testing for Module**, then click **Publish module**


## 4.2 Configure Testing
We now need to add environment variables for our module testing. If you are following along with live with our lab, you can get these details from the terminal. Run the following to get the details:

```bash
echo $AWS_ACCESS_KEY_ID && echo $AWS_SECRET_ACCESS_KEY
```

To configure environment variables on HCP for the tests, click **Configure Tests** on the module's page.

Go to **Module variables**, and click the **+ Add variable** button and add each of the following environment variables:

|Key|Value|Sensitive|
|---|-----|---------|
|AWS_ACCESS_KEY_ID|Your AWS IAM Key ID|True|
|AWS_SECRET_ACCESS_KEY|Your AWS IAM Key Secret|True|
|AWS_REGION|us-east-1|False|

## 4.3 Run test from CLI
Now let's run the tests in HCP Terraform Cloud by triggering them from our terminal. First we need to change branch

```bash
cd $work_dir && git checkout HCP
```

Now we can run our tests. You will need to make a note of your Terraform Cloud organisation name and replace <org-name> in the following command

```bash
terraform init && terraform test -cloud-run=app.terraform.io/<org-name>/terraform-test/aws
```