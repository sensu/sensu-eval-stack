SparkleFormation.new(:sensu).load(:base, :compute, :in_a_vpc).overrides do
  zone = registry!(:zones).first
  registry!(:official_amis, :sensu, :type => 'ebs')
  rabbitmq_password = ::SecureRandom.hex

  parameters do
    sensu_repo_user do
      type 'String'
      description 'Username for Sensu Enterprise Repo'
      default ENV['SENSU_ENTERPRISE_USER']
    end

    sensu_repo_pass do
      type 'String'
      description 'Password for Sensu Enterprise Repo'
      default ENV['SENSU_ENTERPRISE_PASS']
    end

    ssh_key_pair do
      type 'String'
      description 'SSH Keypair'
    end

    vpc_id do
      type 'String'
      description 'VPC to Join'
    end

    set!(['public_', zone.gsub('-','_'), '_subnet'].join) do
      type 'String'
      description 'Subnet to join'
    end
  end

  resources do
    sensu_ec2_instance do
      type 'AWS::EC2::Instance'
      properties do
        image_id map!(:official_amis, region!, 'trusty')
        instance_type 'm3.large'
        iam_instance_profile ref!(:sensu_instance_profile)
        key_name ref!(:ssh_key_pair)
        network_interfaces array!(
          -> {
            associate_public_ip_address true
            device_index 0
            subnet_id ref!(['public_', zone.gsub('-','_'), '_subnet'].join.to_sym)
            group_set [ ref!(:sensu_security_group) ]
          }
        )
        registry!(:init_and_signal_user_data, :sensu, :init_resource => :sensu_ec2_instance, :signal_resource => :sensu_ec2_instance)
      end
      creation_policy do
        resource_signal do
          count 1
          timeout 'PT15M'
        end
      end
      metadata('AWS::CloudFormation::Init') do
        _camel_keys_set(:auto_disable)
        configSets do
          default [ ]
        end
      end
      registry!(:rabbitmq, :queue_password => rabbitmq_password)
      registry!(:redis)
      registry!(:sensu_enterprise, :queue_password => rabbitmq_password)
      registry!(:sensu_client, :queue_password => rabbitmq_password)
    end

    sensu_instance_profile do
      type 'AWS::IAM::InstanceProfile'
      properties do
        path '/'
        roles [ ref!(:cfn_role) ]
      end
    end
  end

  dynamic!(:security_group_with_rules, :sensu,
    :ingress => {
      :ssh => {
        :protocol => 'tcp',
        :ports => 22
      },
      :http => {
        :protocol => 'tcp',
        :ports => 3000
      },
      :rabbitmq => {
        :protocol => 'tcp',
        :ports => 5671
      }
    },
    :egress => {
      :all => {
        :protocol => '-1',
        :ports => [1, 65535]
      }
    }
  )

  outputs do
    ssh_address do
      value join!('ubuntu@', attr!(:sensu_ec2_instance, :public_dns_name))
    end
    public_rabbitmq_host do
      value attr!(:sensu_ec2_instance, :public_dns_name)
    end
    private_rabbit_host do
      value attr!(:sensu_ec2_instance, :private_dns_name)
    end
    sensu_dashboard_url do
      value join!('http://', attr!(:sensu_ec2_instance, :public_dns_name), ':3000')
    end
  end
end
