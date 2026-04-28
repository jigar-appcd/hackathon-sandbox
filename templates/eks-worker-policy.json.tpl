{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::*${lower(application_name)}*",
                "arn:aws:s3:::*${lower(application_name)}*/*"
            ],
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*",
                "s3:Delete*"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:CompleteLifecycleAction"
            ]
        },
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateTags"
			],
			"Resource": "*"
		}
    ]
}
