> [!WARNING]
> **This repository is scheduled to be archived on 13th November 2026.**
>
> After that date it will be read-only: no new commits, issues, or pull requests, and no further maintenance or security updates will be issued.

## Sensu Enterprise Evaluation Stack
This repository provides [SparkleFormation](http://www.sparkleformation.io/) templates to build a Sensu Enterprise Evaluation server in AWS. The server configuration will be roughly equivalent to the [Sensu installation instructions](https://sensuapp.org/docs/latest/installation-overview). This stack uses a single m3.large instance. Please review AWS pricing ahead of time to understand the billing implications of running this stack.

### Prerequisites
You will need valid [Sensu Enterprise](https://sensuapp.org/sensu-enterprise) credentials and an AWS account with a VPC and an SSH keypair.
You will also need a modern Ruby installation (greater than 2.0.0) with [Bundler](http://bundler.io/) installed.

### Usage
Export the following Environment Variables:
* `AWS_ACCESS_KEY_ID`: Your AWS Access Key with permissions to build Cloudformation Stacks.
* `AWS_SECRET_ACCESS_KEY`: The Secret Key associated with your Access Key ID.
* `AWS_REGION`: The region in which you're building.
* `SENSU_ENTERPRISE_USER`: Your Sensu Enterprise Repository Username (this can also be entered at runtime when prompted).
* `SENSU_ENTERPRISE_PASS`: Your Sensu Enterprise Repository Password (this can also be entered at runtime when prompted).

You should additionally collect the following values which you'll enter when prompted:
* Your VPC ID.
* You VPC Public Subnet IDs (you will be prompted for a specific AZ, usually "a" within the region you've chosen, e.g. us-west-2a.
* Your SSH Keypair name.

To build the stack, run the following commands:
```ruby
bundle install
bundle exec sfn create <your-stack-name>
```
You will be prompted as follows:
```
[Sfn]: Please select an entry:
Templates:
  1. Sensu
[Sfn]: Enter selection:
```
Enter `1` then follow the prompts. The values in `[]` are defaults.

When the stack completes, you'll see outputs like:
```
[Sfn]: Stack create complete: SUCCESS
[Sfn]: Stack description of <your-stack-name>:
[Sfn]: Outputs for stack: sensu-eval-stack-those-examples
[Sfn]:    Ssh Address: ubuntu@ec2-52-37-76-105.us-west-2.compute.amazonaws.com
[Sfn]:    Public Rabbitmq Host: ec2-52-37-76-105.us-west-2.compute.amazonaws.com
[Sfn]:    Private Rabbit Host: ip-10-0-0-245.us-west-2.compute.internal
[Sfn]:    Sensu Dashboard Url: http://ec2-52-37-76-105.us-west-2.compute.amazonaws.com:3000
```
To view these outputs in the future, execute:
```
bundle exec sfn describe -o <your-stack-name>
```
### Using Your Evaluation Install
You should be able to access the Sensu Enterprise dashboard at the provided URL with no authentication. Keep this in mind as you experiment with the stack.

You can download a sample Sensu Client config file from the ubuntu home folder via `scp` (make sure your key is added to your ssh agent):
```
scp ubuntu@ec2-52-37-76-105.us-west-2.compute.amazonaws.com:~/sensu_client_example.json ./
```

### Destroying the Evaluation Stack
To destroy the stack, execute:
```
bundle exec sfn destroy <your-stack-name>
```
