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
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:PutObject",
                "s3:DeleteObject"
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
			"Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:network-interface/*"
            ]
		}
    ]
}
