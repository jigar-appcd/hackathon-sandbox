<powershell>
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"
& $EKSBootstrapScriptFile -EKSClusterName "${resource_name}" -APIServerEndpoint "${master_endpoint}" -Base64ClusterCA "${cluster_ca}" -DNSClusterIP "${dns_cluster_ip}" -KubeletExtraArgs "--node-labels=nodegroup=${node_group},${node_labels} --register-with-taints=${node_taints}" 3>&1 4>&1 5>&1 6>&1
</powershell>